/**
 * @typedef {Object} QuizOption
 * @property {string} id
 * @property {string} question_id
 * @property {string} option_text
 * @property {boolean} is_correct
 * @property {number} order_index
 */

/**
 * @typedef {Object} QuizQuestion
 * @property {string} id
 * @property {string} quiz_id
 * @property {string} question_text
 * @property {string} question_type
 * @property {number} points
 * @property {number} order_index
 * @property {boolean} is_required
 * @property {QuizOption[]} quiz_question_options
 */

/**
 * @typedef {Object} QuizSummary
 * @property {string} id
 * @property {string} title
 * @property {string} description
 * @property {string} course_id
 * @property {string} instructor_id
 * @property {string} start_date
 * @property {string} due_date
 * @property {string} late_due_date
 * @property {boolean} allow_late_submission
 * @property {number} max_attempts
 * @property {number} time_limit
 * @property {boolean} shuffle_questions
 * @property {boolean} shuffle_options
 * @property {boolean} show_correct_answers
 * @property {boolean} is_active
 * @property {string} created_at
 * @property {string} updated_at
 */

module.exports = {};



