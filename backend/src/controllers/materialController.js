const { supabase } = require('../services/supabaseClient');
const { buildResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');

/**
 * Material Controller
 * Handles all material-related operations
 */
class MaterialController {
  /**
   * Create new material
   */
  createMaterial = catchAsync(async (req, res) => {
    const {
      title,
      description,
      courseId,
      attachmentIds = []
    } = req.body;

    const instructorId = req.user.id;

    // Start transaction
    const { data: material, error: materialError } = await supabase
      .from('materials')
      .insert({
        title,
        description,
        course_id: courseId,
        instructor_id: instructorId
      })
      .select()
      .single();

    if (materialError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to create material', null, materialError.message)
      );
    }

    // Add file attachments if provided
    if (attachmentIds && attachmentIds.length > 0) {
      const { data: tempAttachments, error: tempError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', attachmentIds)
        .eq('user_id', instructorId)
        .eq('is_finalized', false);

      if (tempError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to retrieve temp attachments', null, tempError.message)
        );
      }

      if (tempAttachments.length !== attachmentIds.length) {
        return res.status(400).json(
          buildResponse(false, 'Some temp attachments not found or already finalized')
        );
      }

      // Create material files
      const materialFiles = tempAttachments.map(temp => ({
        material_id: material.id,
        file_name: temp.file_name,
        file_url: temp.file_url,
        file_size: temp.file_size,
        file_type: temp.file_type
      }));

      const { error: filesError } = await supabase
        .from('material_attachments')
        .insert(materialFiles);

      if (filesError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to attach files to material', null, filesError.message)
        );
      }

      // Mark temp attachments as finalized
      const { error: finalizeError } = await supabase
        .from('temp_attachments')
        .update({ is_finalized: true })
        .in('temp_id', attachmentIds);

      if (finalizeError) {
        console.warn('Failed to finalize temp attachments:', finalizeError.message);
      }
    }

    // Fetch complete material with relations
    const completeMaterial = await this.getMaterialWithRelations(material.id);

    res.status(201).json(
      buildResponse(true, 'Material created successfully', {
        material: completeMaterial
      })
    );
  });

  /**
   * Get materials with filters and pagination
   */
  getMaterials = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      courseId,
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const instructorId = req.user.id;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('materials')
      .select(`
        *,
        courses!inner(id, code, name),
        users!materials_instructor_id_fkey(id, full_name, email),
        material_attachments(id, file_name, file_url, file_size, file_type),
        material_views(id, view_count)
      `)
      .eq('instructor_id', instructorId)
      .eq('is_active', true);

    // Apply filters
    if (courseId) {
      query = query.eq('course_id', courseId);
    }

    if (search) {
      query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + limit - 1);

    const { data: materials, error } = await query;

    if (error) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch materials', null, error.message)
      );
    }

    // Get total count separately with same filters
    let countQuery = supabase
      .from('materials')
      .select('*', { count: 'exact', head: true })
      .eq('instructor_id', instructorId)
      .eq('is_active', true);

    // Apply same filters for count
    if (courseId) {
      countQuery = countQuery.eq('course_id', courseId);
    }

    if (search) {
      countQuery = countQuery.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
    }

    const { count: totalCount } = await countQuery;

    // Format response
    const formattedMaterials = materials.map(mat => {
      // Calculate total view count by summing all view_count values
      const totalViewCount = mat.material_views?.reduce((sum, view) => sum + (view.view_count || 0), 0) || 0;
      console.log(`📊 Material ${mat.id} viewCount calculation:`, {
        material_views: mat.material_views,
        totalViewCount: totalViewCount
      });
      
      return {
        id: mat.id,
        title: mat.title,
        description: mat.description,
        createdAt: mat.created_at,
        updatedAt: mat.updated_at,
        course: {
          id: mat.courses.id,
          code: mat.courses.code,
          name: mat.courses.name
        },
        instructor: {
          id: mat.users.id,
          fullName: mat.users.full_name,
          email: mat.users.email
        },
        files: mat.material_attachments || [],
        viewCount: totalViewCount
      };
    });

    const totalPages = Math.ceil((totalCount || 0) / limit);

    res.json(
      buildResponse(true, 'Materials fetched successfully', {
        materials: formattedMaterials,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: totalCount || 0,
          pages: totalPages
        }
      })
    );
  });

  /**
   * Get material by ID
   */
  getMaterialById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const instructorId = req.user.id;
    const userRole = req.user.role;

    // Auto track view when material is accessed (for all users) - BEFORE permission check
    try {
      console.log(`🔍 Tracking view for material: ${id}, user: ${req.user.id}`);
      
      // Check if view already exists
      const { data: existingView, error: selectError } = await supabase
        .from('material_views')
        .select('id, view_count')
        .eq('material_id', id)
        .eq('student_id', req.user.id)
        .single();

      if (selectError && selectError.code !== 'PGRST116') {
        console.error('❌ Error checking existing view:', selectError);
        throw selectError;
      }

      if (existingView) {
        console.log(`📊 Updating existing view: ${existingView.view_count} -> ${existingView.view_count + 1}`);
        // Update existing view count
        const { error: updateError } = await supabase
          .from('material_views')
          .update({
            view_count: existingView.view_count + 1,
            viewed_at: new Date().toISOString()
          })
          .eq('id', existingView.id);

        if (updateError) {
          console.error('❌ Error updating view count:', updateError);
          throw updateError;
        }
        console.log('✅ View count updated successfully');
      } else {
        console.log('🆕 Creating new view record');
        // Create new view record
        const { error: insertError } = await supabase
          .from('material_views')
          .insert({
            material_id: id,
            student_id: req.user.id,
            viewed_at: new Date().toISOString(),
            view_count: 1
          });

        if (insertError) {
          console.error('❌ Error creating view record:', insertError);
          throw insertError;
        }
        console.log('✅ New view record created successfully');
      }
    } catch (error) {
      console.error('❌ Failed to track material view:', error.message);
      // Don't fail the request if tracking fails
    }

    const material = await this.getMaterialWithRelations(id);

    if (!material) {
      return res.status(404).json(
        buildResponse(false, 'Material not found')
      );
    }

    // Check if instructor owns this material
    if (material.instructor.id !== instructorId) {
      return res.status(403).json(
        buildResponse(false, 'Access denied')
      );
    }

    res.json(
      buildResponse(true, 'Material fetched successfully', {
        material: material
      })
    );
  });

  /**
   * Update material
   */
  updateMaterial = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { title, description, attachmentIds = [] } = req.body;
    const instructorId = req.user.id;

    // Check if material exists and belongs to instructor
    const { data: existingMaterial, error: fetchError } = await supabase
      .from('materials')
      .select('*')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_active', true)
      .single();

    if (fetchError || !existingMaterial) {
      return res.status(404).json(
        buildResponse(false, 'Material not found or access denied')
      );
    }

    // Update material
    const { error: updateError } = await supabase
      .from('materials')
      .update({
        title,
        description,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to update material', null, updateError.message)
      );
    }

    // Handle file attachments if provided
    if (attachmentIds && attachmentIds.length > 0) {
      // Remove existing files
      const { error: deleteFilesError } = await supabase
        .from('material_attachments')
        .delete()
        .eq('material_id', id);

      if (deleteFilesError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to remove existing files', null, deleteFilesError.message)
        );
      }

      // Add new files
      const { data: tempAttachments, error: tempError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', attachmentIds)
        .eq('user_id', instructorId)
        .eq('is_finalized', false);

      if (tempError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to retrieve temp attachments', null, tempError.message)
        );
      }

      const materialFiles = tempAttachments.map(temp => ({
        material_id: id,
        file_name: temp.file_name,
        file_url: temp.file_url,
        file_size: temp.file_size,
        file_type: temp.file_type
      }));

      const { error: filesError } = await supabase
        .from('material_attachments')
        .insert(materialFiles);

      if (filesError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to attach files to material', null, filesError.message)
        );
      }

      // Mark temp attachments as finalized
      const { error: finalizeError } = await supabase
        .from('temp_attachments')
        .update({ is_finalized: true })
        .in('temp_id', attachmentIds);

      if (finalizeError) {
        console.warn('Failed to finalize temp attachments:', finalizeError.message);
      }
    }

    // Fetch complete updated material
    const completeMaterial = await this.getMaterialWithRelations(id);

    res.json(
      buildResponse(true, 'Material updated successfully', {
        material: completeMaterial
      })
    );
  });

  /**
   * Delete material (soft delete)
   */
  deleteMaterial = catchAsync(async (req, res) => {
    const { id } = req.params;
    const instructorId = req.user.id;

    // Check if material exists and belongs to instructor
    const { data: existingMaterial, error: fetchError } = await supabase
      .from('materials')
      .select('*')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_active', true)
      .single();

    if (fetchError || !existingMaterial) {
      return res.status(404).json(
        buildResponse(false, 'Material not found or access denied')
      );
    }

    // Soft delete material
    const { error: deleteError } = await supabase
      .from('materials')
      .update({ is_active: false })
      .eq('id', id);

    if (deleteError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to delete material', null, deleteError.message)
      );
    }

    res.json(
      buildResponse(true, 'Material deleted successfully')
    );
  });






  /**
   * Helper method to get material with all relations
   */
  async getMaterialWithRelations(materialId) {
    const { data: material, error } = await supabase
      .from('materials')
      .select(`
        *,
        courses!inner(id, code, name),
        users!materials_instructor_id_fkey(id, full_name, email),
        material_attachments(id, file_name, file_url, file_size, file_type),
        material_views(id, view_count)
      `)
      .eq('id', materialId)
      .eq('is_active', true)
      .single();

    if (error || !material) {
      return null;
    }

    // Calculate total view count by summing all view_count values
    const totalViewCount = material.material_views?.reduce((sum, view) => sum + (view.view_count || 0), 0) || 0;
    console.log(`📊 Material ${materialId} viewCount calculation:`, {
      material_views: material.material_views,
      totalViewCount: totalViewCount
    });

    return {
      id: material.id,
      title: material.title,
      description: material.description,
      createdAt: material.created_at,
      updatedAt: material.updated_at,
      course: {
        id: material.courses.id,
        code: material.courses.code,
        name: material.courses.name
      },
      instructor: {
        id: material.users.id,
        fullName: material.users.full_name,
        email: material.users.email
      },
      files: material.material_attachments || [],
      viewCount: totalViewCount
    };
  }
}

module.exports = new MaterialController();
