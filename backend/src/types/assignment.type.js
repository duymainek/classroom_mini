/**
 * @typedef {Object} AssignmentAttachment
 * @property {string} id
 * @property {string} fileName
 * @property {string} fileUrl
 * @property {number} fileSize
 * @property {string} fileType
 * @property {string} createdAt
 */

/**
 * @typedef {Object} AssignmentGroup
 * @property {{ id: string, name: string }} groups
 */

/**
 * @typedef {Object} AssignmentSummary
 * @property {string} id
 * @property {string} title
 * @property {string} description
 * @property {string} courseId
 * @property {string} instructorId
 * @property {string} startDate
 * @property {string} dueDate
 * @property {string} lateDueDate
 * @property {boolean} allowLateSubmission
 * @property {number} maxAttempts
 * @property {string[]} fileFormats
 * @property {number} maxFileSize
 * @property {boolean} isActive
 * @property {string} createdAt
 * @property {string} updatedAt
 * @property {{ code: string, name: string }} courses
 */

/**
 * @typedef {Object} AssignmentDetail
 * @property {string} id
 * @property {string} title
 * @property {string} description
 * @property {string} courseId
 * @property {string} instructorId
 * @property {string} startDate
 * @property {string} dueDate
 * @property {string} lateDueDate
 * @property {boolean} allowLateSubmission
 * @property {number} maxAttempts
 * @property {string[]} fileFormats
 * @property {number} maxFileSize
 * @property {boolean} isActive
 * @property {string} createdAt
 * @property {string} updatedAt
 * @property {{ code: string, name: string }} courses
 * @property {AssignmentAttachment[]} assignmentAttachments
 * @property {AssignmentGroup[]} assignmentGroups
 */

module.exports = {};



