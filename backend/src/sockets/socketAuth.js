const { verifyAccessToken } = require('../utils/tokenUtils');

const socketAuthMiddleware = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.query.token;
    
    if (!token) {
      return next(new Error('Authentication error: No token provided'));
    }

    const decoded = verifyAccessToken(token);
    
    socket.userId = decoded.userId;
    socket.userRole = decoded.role;
    
    console.log(`Socket authenticated: User ${socket.userId}`);
    next();
    
  } catch (error) {
    console.error('Socket auth error:', error);
    next(new Error('Authentication error: Invalid token'));
  }
};

module.exports = { socketAuthMiddleware };

