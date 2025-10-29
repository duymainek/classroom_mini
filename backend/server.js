const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./src/routes/auth');
const studentRoutes = require('./src/routes/students');
const semesterRoutes = require('./src/routes/semesters');
const courseRoutes = require('./src/routes/courses');
const groupRoutes = require('./src/routes/groups');
const dashboardRoutes = require('./src/routes/dashboard');
const assignmentRoutes = require('./src/routes/assignments');
const submissionRoutes = require('./src/routes/submissions');
const profileRoutes = require('./src/routes/profile');
const quizRoutes = require('./src/routes/quizzes');
const announcementRoutes = require('./src/routes/announcements');
const materialRoutes = require('./src/routes/materials');
const forumRoutes = require('./src/routes/forum');
const fileUploadRoutes = require('./src/routes/fileUploadRoutes');
const { errorHandler, notFoundHandler } = require('./src/middleware/errorHandler');
const { testConnection, initializeAdminUser } = require('./src/services/supabaseClient');

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy (important for rate limiting and IP detection)
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));


// TEMPORARY: Allow all origins for testing
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Compression middleware
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.',
    code: 'RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Apply rate limiting to API routes
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ 
  limit: '10mb',
  type: 'application/json'
}));
app.use(express.urlencoded({ 
  extended: true,
  limit: '10mb'
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Classroom Mini API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/semesters', semesterRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/submissions', submissionRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/announcements', announcementRoutes);
app.use('/api/materials', materialRoutes);
app.use('/api/forum', forumRoutes);
app.use('/api', fileUploadRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Classroom Mini API',
    version: '1.0.0',
    documentation: '/api/docs', // Could be implemented later
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      students: '/api/students',
      semesters: '/api/semesters',
      courses: '/api/courses',
      groups: '/api/groups',
      dashboard: '/api/dashboard',
      assignments: '/api/assignments',
      submissions: '/api/submissions',
      quizzes: '/api/quizzes',
      announcements: '/api/announcements',
      materials: '/api/materials',
      forum: '/api/forum'
    }
  });
});

// Handle 404 for undefined routes
app.use(notFoundHandler);

// Global error handling middleware
app.use(errorHandler);

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

// Unhandled promise rejection handler
process.on('unhandledRejection', (err) => {
  console.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Uncaught exception handler
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

// Start server
async function startServer() {
  try {
    console.log('🚀 Starting Classroom Mini API Server...');
    
    // Test database connection
    console.log('📡 Testing Supabase connection...');
    const isConnected = await testConnection();
    
    if (!isConnected) {
      console.error('❌ Failed to connect to Supabase. Please check your configuration.');
      process.exit(1);
    }

    // Initialize admin user
    console.log('👤 Initializing admin user...');
    await initializeAdminUser();

    // Start the server
    app.listen(PORT, () => {
      console.log(`✅ Server is running on port ${PORT}`);
      console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`📍 API URL: http://localhost:${PORT}`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
      console.log(`🔐 Auth Endpoints: http://localhost:${PORT}/api/auth`);
      
      if (process.env.NODE_ENV === 'development') {
        console.log(`🧪 Test Endpoint: http://localhost:${PORT}/api/auth/test`);
      }
    });

  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

module.exports = app;