const { verifyAccessToken } = require('../utils/tokenUtils');

const socketAuthMiddleware = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.query.token;
    
    if (token) {
      try {
        const decoded = verifyAccessToken(token);
        socket.userId = decoded.userId;
        socket.userRole = decoded.role;
        console.log(`Socket authenticated with token: User ${socket.userId}`);
      } catch (error) {
        console.warn('Token verification failed, falling back to userId from handshake:', error.message);
        socket.userId = socket.handshake.auth.userId || socket.handshake.query.userId;
        socket.userRole = socket.handshake.auth.role || socket.handshake.query.role;
        
        if (!socket.userId) {
          console.warn('No userId provided in handshake, connection may be limited');
        } else {
          console.log(`Socket authenticated with userId from handshake: User ${socket.userId}`);
        }
      }
    } else {
      socket.userId = socket.handshake.auth.userId || socket.handshake.query.userId;
      socket.userRole = socket.handshake.auth.role || socket.handshake.query.role;
      
      if (!socket.userId) {
        console.warn('No token or userId provided, connection may be limited');
      } else {
        console.log(`Socket connected without token, using userId from handshake: User ${socket.userId}`);
      }
    }
    
    next();
    
  } catch (error) {
    console.error('Socket auth error:', error);
    next();
  }
};

module.exports = { socketAuthMiddleware };

