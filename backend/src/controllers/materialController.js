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
        material_views(id)
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

    const { data: materials, error, count } = await query;

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
    const formattedMaterials = materials.map(mat => ({
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
      viewCount: mat.material_views?.length || 0
    }));

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
    const { data: updatedMaterial, error: updateError } = await supabase
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
   * Track material view
   */
  trackView = catchAsync(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Only students can track views
    if (userRole !== 'student') {
      return res.status(403).json(
        buildResponse(false, 'Only students can track material views')
      );
    }

    // Check if view already exists
    const { data: existingView, error: fetchError } = await supabase
      .from('material_views')
      .select('*')
      .eq('material_id', id)
      .eq('student_id', userId)
      .single();

    if (existingView) {
      // Update view count
      const { error: updateError } = await supabase
        .from('material_views')
        .update({
          view_count: existingView.view_count + 1,
          viewed_at: new Date().toISOString()
        })
        .eq('id', existingView.id);

      if (updateError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to update view', null, updateError.message)
        );
      }
    } else {
      // Create new view
      const { error: createError } = await supabase
        .from('material_views')
        .insert({
          material_id: id,
          student_id: userId,
          viewed_at: new Date().toISOString(),
          view_count: 1
        });

      if (createError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to track view', null, createError.message)
        );
      }
    }

    res.json(
      buildResponse(true, 'View tracked successfully')
    );
  });

  /**
   * Track file download
   */
  trackDownload = catchAsync(async (req, res) => {
    const { fileId } = req.params;
    const studentId = req.user.id;

    // Check if download already exists
    const { data: existingDownload, error: fetchError } = await supabase
      .from('material_downloads')
      .select('*')
      .eq('file_id', fileId)
      .eq('student_id', studentId)
      .single();

    if (existingDownload) {
      // Update download count
      const { error: updateError } = await supabase
        .from('material_downloads')
        .update({
          download_count: existingDownload.download_count + 1,
          downloaded_at: new Date().toISOString()
        })
        .eq('id', existingDownload.id);

      if (updateError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to update download', null, updateError.message)
        );
      }
    } else {
      // Create new download
      const { error: createError } = await supabase
        .from('material_downloads')
        .insert({
          file_id: fileId,
          student_id: studentId,
          downloaded_at: new Date().toISOString(),
          download_count: 1
        });

      if (createError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to track download', null, createError.message)
        );
      }
    }

    res.json(
      buildResponse(true, 'Download tracked successfully')
    );
  });

  /**
   * Get material tracking data
   */
  getMaterialTracking = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { groupId, status } = req.query;
    const instructorId = req.user.id;

    // Check if material belongs to instructor
    const { data: material, error: materialError } = await supabase
      .from('materials')
      .select('id')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_active', true)
      .single();

    if (materialError || !material) {
      return res.status(404).json(
        buildResponse(false, 'Material not found or access denied')
      );
    }

    // Get all students in the course
    const { data: students, error: studentsError } = await supabase
      .from('student_enrollments')
      .select(`
        users!student_enrollments_student_id_fkey(id, full_name, email),
        groups!student_enrollments_group_id_fkey(id, name)
      `)
      .eq('semester_id', req.user.current_semester_id);

    if (studentsError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch students', null, studentsError.message)
      );
    }

    // Get view tracking data
    const { data: views, error: viewsError } = await supabase
      .from('material_views')
      .select('student_id, viewed_at, view_count')
      .eq('material_id', id);

    if (viewsError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch view data', null, viewsError.message)
      );
    }

    // Combine data
    const trackingData = students.map(student => {
      const viewData = views.find(v => v.student_id === student.users.id);
      return {
        student: {
          id: student.users.id,
          fullName: student.users.full_name,
          email: student.users.email
        },
        group: {
          id: student.groups.id,
          name: student.groups.name
        },
        viewed: !!viewData,
        viewedAt: viewData?.viewed_at,
        viewCount: viewData?.view_count || 0
      };
    });

    // Apply status filter
    let filteredData = trackingData;
    if (status === 'viewed') {
      filteredData = trackingData.filter(item => item.viewed);
    } else if (status === 'not_viewed') {
      filteredData = trackingData.filter(item => !item.viewed);
    }

    res.json(
      buildResponse(true, 'Tracking data fetched successfully', {
        tracking: filteredData,
        summary: {
          total: trackingData.length,
          viewed: trackingData.filter(item => item.viewed).length,
          notViewed: trackingData.filter(item => !item.viewed).length
        }
      })
    );
  });

  /**
   * Get file download tracking data
   */
  getFileDownloadTracking = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { fileId } = req.query;
    const instructorId = req.user.id;

    // Check if material belongs to instructor
    const { data: material, error: materialError } = await supabase
      .from('materials')
      .select('id')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_active', true)
      .single();

    if (materialError || !material) {
      return res.status(404).json(
        buildResponse(false, 'Material not found or access denied')
      );
    }

    // Get files for this material
    let filesQuery = supabase
      .from('material_attachments')
      .select('*')
      .eq('material_id', id);

    if (fileId) {
      filesQuery = filesQuery.eq('id', fileId);
    }

    const { data: files, error: filesError } = await filesQuery;

    if (filesError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch files', null, filesError.message)
      );
    }

    // Get download tracking for each file
    const fileTrackingData = await Promise.all(
      files.map(async (file) => {
        const { data: downloads, error: downloadsError } = await supabase
          .from('material_downloads')
          .select(`
            student_id,
            downloaded_at,
            download_count,
            users!material_downloads_student_id_fkey(id, full_name, email)
          `)
          .eq('file_id', file.id);

        if (downloadsError) {
          console.error('Failed to fetch downloads for file:', file.id, downloadsError);
          return {
            file: {
              id: file.id,
              fileName: file.file_name,
              fileSize: file.file_size,
              fileType: file.file_type
            },
            downloads: [],
            totalDownloads: 0
          };
        }

        return {
          file: {
            id: file.id,
            fileName: file.file_name,
            fileSize: file.file_size,
            fileType: file.file_type
          },
          downloads: downloads.map(download => ({
            student: {
              id: download.users.id,
              fullName: download.users.full_name,
              email: download.users.email
            },
            downloadedAt: download.downloaded_at,
            downloadCount: download.download_count
          })),
          totalDownloads: downloads.reduce((sum, d) => sum + d.download_count, 0)
        };
      })
    );

    res.json(
      buildResponse(true, 'File download tracking fetched successfully', {
        files: fileTrackingData
      })
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
        material_views(id)
      `)
      .eq('id', materialId)
      .eq('is_active', true)
      .single();

    if (error || !material) {
      return null;
    }

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
      viewCount: material.material_views?.length || 0
    };
  }
}

module.exports = new MaterialController();
