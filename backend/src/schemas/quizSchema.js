const Joi = require('joi');

// Quiz creation schema
const createQuizSchema = Joi.object({
  title: Joi.string()
    .min(2)
    .max(255)
    .required()
    .messages({
      'string.min': 'Quiz title must be at least 2 characters',
      'string.max': 'Quiz title cannot exceed 255 characters',
      'any.required': 'Quiz title is required'
    }),
  
  description: Joi.string()
    .max(5000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Description cannot exceed 5000 characters'
    }),
  
  courseId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.uuid': 'Course ID must be a valid UUID',
      'any.required': 'Course ID is required'
    }),
  
  startDate: Joi.date()
    .iso()
    .required()
    .messages({
      'date.format': 'Start date must be a valid ISO date',
      'any.required': 'Start date is required'
    }),
  
  dueDate: Joi.date()
    .iso()
    .min(Joi.ref('startDate'))
    .required()
    .messages({
      'date.format': 'Due date must be a valid ISO date',
      'date.min': 'Due date must be after start date',
      'any.required': 'Due date is required'
    }),
  
  lateDueDate: Joi.alternatives()
    .try(
      Joi.date().iso().min(Joi.ref('dueDate')).messages({
        'date.format': 'Late due date must be a valid ISO date',
        'date.min': 'Late due date must be after due date'
      }),
      Joi.valid(null)
    )
    .optional(),
  
  allowLateSubmission: Joi.boolean()
    .optional()
    .default(false),
  
  maxAttempts: Joi.number()
    .integer()
    .min(1)
    .max(10)
    .optional()
    .default(1)
    .messages({
      'number.min': 'Max attempts must be at least 1',
      'number.max': 'Max attempts cannot exceed 10'
    }),
  
  timeLimit: Joi.number()
    .integer()
    .min(1)
    .max(300) // 5 hours max
    .optional()
    .allow(null)
    .messages({
      'number.min': 'Time limit must be at least 1 minute',
      'number.max': 'Time limit cannot exceed 300 minutes'
    }),
  
  shuffleQuestions: Joi.boolean()
    .optional()
    .default(false),
  
  shuffleOptions: Joi.boolean()
    .optional()
    .default(false),
  
  showCorrectAnswers: Joi.boolean()
    .optional()
    .default(false),
  
  groupIds: Joi.array()
    .items(Joi.string().uuid())
    .min(1)
    .optional()
    .messages({
      'array.min': 'At least one group must be selected',
      'string.uuid': 'Group ID must be a valid UUID'
    })
});

// Quiz update schema
const updateQuizSchema = Joi.object({
  title: Joi.string()
    .min(2)
    .max(255)
    .optional()
    .messages({
      'string.min': 'Quiz title must be at least 2 characters',
      'string.max': 'Quiz title cannot exceed 255 characters'
    }),
  
  description: Joi.string()
    .max(5000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Description cannot exceed 5000 characters'
    }),
  
  startDate: Joi.date()
    .iso()
    .optional()
    .messages({
      'date.format': 'Start date must be a valid ISO date'
    }),
  
  dueDate: Joi.date()
    .iso()
    .optional()
    .messages({
      'date.format': 'Due date must be a valid ISO date'
    }),
  
  lateDueDate: Joi.alternatives()
    .try(
      Joi.date().iso().messages({ 'date.format': 'Late due date must be a valid ISO date' }),
      Joi.valid(null)
    )
    .optional(),
  
  allowLateSubmission: Joi.boolean()
    .optional(),
  
  maxAttempts: Joi.number()
    .integer()
    .min(1)
    .max(10)
    .optional()
    .messages({
      'number.min': 'Max attempts must be at least 1',
      'number.max': 'Max attempts cannot exceed 10'
    }),
  
  timeLimit: Joi.number()
    .integer()
    .min(1)
    .max(300)
    .optional()
    .allow(null)
    .messages({
      'number.min': 'Time limit must be at least 1 minute',
      'number.max': 'Time limit cannot exceed 300 minutes'
    }),
  
  shuffleQuestions: Joi.boolean()
    .optional(),
  
  shuffleOptions: Joi.boolean()
    .optional(),
  
  showCorrectAnswers: Joi.boolean()
    .optional(),
  
  isActive: Joi.boolean()
    .optional()
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

// Question creation schema
const createQuestionSchema = Joi.object({
  questionText: Joi.string()
    .min(5)
    .max(2000)
    .required()
    .messages({
      'string.min': 'Question text must be at least 5 characters',
      'string.max': 'Question text cannot exceed 2000 characters',
      'any.required': 'Question text is required'
    }),
  
  questionType: Joi.string()
    .valid('multiple_choice', 'true_false', 'essay')
    .required()
    .messages({
      'any.only': 'Question type must be multiple_choice, true_false, or essay',
      'any.required': 'Question type is required'
    }),
  
  points: Joi.number()
    .integer()
    .min(1)
    .max(100)
    .optional()
    .default(1)
    .messages({
      'number.min': 'Points must be at least 1',
      'number.max': 'Points cannot exceed 100'
    }),
  
  orderIndex: Joi.number()
    .integer()
    .min(1)
    .required()
    .messages({
      'number.min': 'Order index must be at least 1',
      'any.required': 'Order index is required'
    }),
  
  isRequired: Joi.boolean()
    .optional()
    .default(true),
  
  options: Joi.array()
    .items(Joi.object({
      optionText: Joi.string().required(),
      isCorrect: Joi.boolean().default(false),
      orderIndex: Joi.number().integer().min(1).required()
    }))
    .min(2)
    .when('questionType', {
      is: 'multiple_choice',
      then: Joi.required(),
      otherwise: Joi.optional()
    })
    .messages({
      'array.min': 'Multiple choice questions must have at least 2 options',
      'any.required': 'Options are required for multiple choice questions'
    })
});

// Question update schema
const updateQuestionSchema = Joi.object({
  questionText: Joi.string()
    .min(5)
    .max(2000)
    .optional()
    .messages({
      'string.min': 'Question text must be at least 5 characters',
      'string.max': 'Question text cannot exceed 2000 characters'
    }),
  
  questionType: Joi.string()
    .valid('multiple_choice', 'true_false', 'essay')
    .optional()
    .messages({
      'any.only': 'Question type must be multiple_choice, true_false, or essay'
    }),
  
  points: Joi.number()
    .integer()
    .min(1)
    .max(100)
    .optional()
    .messages({
      'number.min': 'Points must be at least 1',
      'number.max': 'Points cannot exceed 100'
    }),
  
  orderIndex: Joi.number()
    .integer()
    .min(1)
    .optional()
    .messages({
      'number.min': 'Order index must be at least 1'
    }),
  
  isRequired: Joi.boolean()
    .optional(),
  
  options: Joi.array()
    .items(Joi.object({
      id: Joi.string().uuid().optional(),
      optionText: Joi.string().required(),
      isCorrect: Joi.boolean().default(false),
      orderIndex: Joi.number().integer().min(1).required()
    }))
    .min(2)
    .optional()
    .messages({
      'array.min': 'Multiple choice questions must have at least 2 options'
    })
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

// Quiz submission schema
const createQuizSubmissionSchema = Joi.object({
  quizId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.uuid': 'Quiz ID must be a valid UUID',
      'any.required': 'Quiz ID is required'
    }),
  
  answers: Joi.array()
    .items(Joi.object({
      questionId: Joi.string().uuid().required(),
      answerText: Joi.string().max(5000).optional().allow(''),
      selectedOptionId: Joi.string().uuid().optional()
    }))
    .min(1)
    .required()
    .messages({
      'array.min': 'At least one answer must be provided',
      'any.required': 'Answers are required'
    })
});

// Grade quiz submission schema
const gradeQuizSubmissionSchema = Joi.object({
  grade: Joi.number()
    .min(0)
    .max(100)
    .required()
    .messages({
      'number.min': 'Grade must be at least 0',
      'number.max': 'Grade must not exceed 100',
      'any.required': 'Grade is required'
    }),
  
  feedback: Joi.string()
    .max(2000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Feedback cannot exceed 2000 characters'
    })
});

function formatQuizResponse(quiz) {
  return {
    id: quiz.id,
    title: quiz.title,
    description: quiz.description,
    courseId: quiz.course_id,
    instructorId: quiz.instructor_id,
    startDate: quiz.start_date,
    dueDate: quiz.due_date,
    lateDueDate: quiz.late_due_date,
    allowLateSubmission: quiz.allow_late_submission,
    maxAttempts: quiz.max_attempts,
    timeLimit: quiz.time_limit,
    shuffleQuestions: quiz.shuffle_questions,
    shuffleOptions: quiz.shuffle_options,
    showCorrectAnswers: quiz.show_correct_answers,
    isActive: quiz.is_active,
    createdAt: quiz.created_at,
    updatedAt: quiz.updated_at,
    course: quiz.courses,
    instructor: quiz.users
  };
}

function formatQuestionResponse(question) {
  return {
    id: question.id,
    quizId: question.quiz_id,
    questionText: question.question_text,
    questionType: question.question_type,
    points: question.points,
    orderIndex: question.order_index,
    isRequired: question.is_required,
    createdAt: question.created_at,
    updatedAt: question.updated_at,
    options: question.options || []
  };
}

function formatQuizSubmissionResponse(submission) {
  return {
    id: submission.id,
    quizId: submission.quiz_id,
    studentId: submission.student_id,
    attemptNumber: submission.attempt_number,
    startedAt: submission.started_at,
    submittedAt: submission.submitted_at,
    timeSpent: submission.time_spent,
    totalScore: submission.total_score,
    maxScore: submission.max_score,
    isLate: submission.is_late,
    isGraded: submission.is_graded,
    grade: submission.grade,
    feedback: submission.feedback,
    gradedAt: submission.graded_at,
    gradedBy: submission.graded_by,
    createdAt: submission.created_at,
    updatedAt: submission.updated_at,
    student: submission.users,
    answers: submission.answers || []
  };
}

module.exports = {
  createQuizSchema,
  updateQuizSchema,
  createQuestionSchema,
  updateQuestionSchema,
  createQuizSubmissionSchema,
  gradeQuizSubmissionSchema,
  formatQuizResponse,
  formatQuestionResponse,
  formatQuizSubmissionResponse
};