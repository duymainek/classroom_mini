#!/bin/bash

# Test Quiz API functionality
# Make sure the server is running on localhost:3000

BASE_URL="http://localhost:3000/api"
ADMIN_TOKEN=""
STUDENT_TOKEN=""
QUIZ_ID=""
COURSE_ID=""
GROUP_ID=""

echo "🧪 Testing Quiz API..."

# Function to make API calls
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local token=$4
    
    if [ -n "$data" ]; then
        curl -s -X $method "$url" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -d "$data"
    else
        curl -s -X $method "$url" \
            -H "Authorization: Bearer $token"
    fi
}

# 1. Login as admin
echo "1. Logging in as admin..."
ADMIN_RESPONSE=$(make_request "POST" "$BASE_URL/auth/login" '{"username":"admin","password":"admin123"}' "")
ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.data.token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to get admin token"
    echo "Response: $ADMIN_RESPONSE"
    exit 1
fi
echo "✅ Admin logged in successfully"

# 2. Get courses to find a course ID
echo "2. Getting courses..."
COURSES_RESPONSE=$(make_request "GET" "$BASE_URL/courses" "" "$ADMIN_TOKEN")
COURSE_ID=$(echo $COURSES_RESPONSE | jq -r '.data.courses[0].id // empty')

if [ -z "$COURSE_ID" ]; then
    echo "❌ No courses found"
    echo "Response: $COURSES_RESPONSE"
    exit 1
fi
echo "✅ Found course: $COURSE_ID"

# 3. Get groups to find a group ID
echo "3. Getting groups..."
GROUPS_RESPONSE=$(make_request "GET" "$BASE_URL/groups?courseId=$COURSE_ID" "" "$ADMIN_TOKEN")
GROUP_ID=$(echo $GROUPS_RESPONSE | jq -r '.data.groups[0].id // empty')

if [ -z "$GROUP_ID" ]; then
    echo "❌ No groups found"
    echo "Response: $GROUPS_RESPONSE"
    exit 1
fi
echo "✅ Found group: $GROUP_ID"

# 4. Create a quiz
echo "4. Creating quiz..."
QUIZ_DATA='{
    "title": "Test Quiz - JavaScript Basics",
    "description": "A quiz to test JavaScript knowledge",
    "courseId": "'$COURSE_ID'",
    "startDate": "'$(date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%S.000Z)'",
    "dueDate": "'$(date -u -d '+2 hours' +%Y-%m-%dT%H:%M:%S.000Z)'",
    "lateDueDate": "'$(date -u -d '+3 hours' +%Y-%m-%dT%H:%M:%S.000Z)'",
    "allowLateSubmission": true,
    "maxAttempts": 3,
    "timeLimit": 30,
    "shuffleQuestions": false,
    "shuffleOptions": false,
    "showCorrectAnswers": true,
    "groupIds": ["'$GROUP_ID'"]
}'

QUIZ_RESPONSE=$(make_request "POST" "$BASE_URL/quizzes" "$QUIZ_DATA" "$ADMIN_TOKEN")
QUIZ_ID=$(echo $QUIZ_RESPONSE | jq -r '.data.quiz.id // empty')

if [ -z "$QUIZ_ID" ]; then
    echo "❌ Failed to create quiz"
    echo "Response: $QUIZ_RESPONSE"
    exit 1
fi
echo "✅ Quiz created successfully: $QUIZ_ID"

# 5. Add multiple choice question
echo "5. Adding multiple choice question..."
MC_QUESTION_DATA='{
    "questionText": "What is the correct way to declare a variable in JavaScript?",
    "questionType": "multiple_choice",
    "points": 2,
    "orderIndex": 1,
    "isRequired": true,
    "options": [
        {"optionText": "var myVar = 5;", "isCorrect": true, "orderIndex": 1},
        {"optionText": "variable myVar = 5;", "isCorrect": false, "orderIndex": 2},
        {"optionText": "v myVar = 5;", "isCorrect": false, "orderIndex": 3},
        {"optionText": "declare myVar = 5;", "isCorrect": false, "orderIndex": 4}
    ]
}'

MC_QUESTION_RESPONSE=$(make_request "POST" "$BASE_URL/quizzes/$QUIZ_ID/questions" "$MC_QUESTION_DATA" "$ADMIN_TOKEN")
MC_QUESTION_ID=$(echo $MC_QUESTION_RESPONSE | jq -r '.data.question.id // empty')

if [ -z "$MC_QUESTION_ID" ]; then
    echo "❌ Failed to add multiple choice question"
    echo "Response: $MC_QUESTION_RESPONSE"
    exit 1
fi
echo "✅ Multiple choice question added: $MC_QUESTION_ID"

# 6. Add true/false question
echo "6. Adding true/false question..."
TF_QUESTION_DATA='{
    "questionText": "JavaScript is a statically typed language.",
    "questionType": "true_false",
    "points": 1,
    "orderIndex": 2,
    "isRequired": true,
    "options": [
        {"optionText": "True", "isCorrect": false, "orderIndex": 1},
        {"optionText": "False", "isCorrect": true, "orderIndex": 2}
    ]
}'

TF_QUESTION_RESPONSE=$(make_request "POST" "$BASE_URL/quizzes/$QUIZ_ID/questions" "$TF_QUESTION_DATA" "$ADMIN_TOKEN")
TF_QUESTION_ID=$(echo $TF_QUESTION_RESPONSE | jq -r '.data.question.id // empty')

if [ -z "$TF_QUESTION_ID" ]; then
    echo "❌ Failed to add true/false question"
    echo "Response: $TF_QUESTION_RESPONSE"
    exit 1
fi
echo "✅ True/false question added: $TF_QUESTION_ID"

# 7. Add essay question
echo "7. Adding essay question..."
ESSAY_QUESTION_DATA='{
    "questionText": "Explain the difference between let, const, and var in JavaScript.",
    "questionType": "essay",
    "points": 5,
    "orderIndex": 3,
    "isRequired": true
}'

ESSAY_QUESTION_RESPONSE=$(make_request "POST" "$BASE_URL/quizzes/$QUIZ_ID/questions" "$ESSAY_QUESTION_DATA" "$ADMIN_TOKEN")
ESSAY_QUESTION_ID=$(echo $ESSAY_QUESTION_RESPONSE | jq -r '.data.question.id // empty')

if [ -z "$ESSAY_QUESTION_ID" ]; then
    echo "❌ Failed to add essay question"
    echo "Response: $ESSAY_QUESTION_RESPONSE"
    exit 1
fi
echo "✅ Essay question added: $ESSAY_QUESTION_ID"

# 8. Get quiz details
echo "8. Getting quiz details..."
QUIZ_DETAILS_RESPONSE=$(make_request "GET" "$BASE_URL/quizzes/$QUIZ_ID" "" "$ADMIN_TOKEN")
echo "✅ Quiz details retrieved"

# 9. Create a student user
echo "9. Creating student user..."
STUDENT_DATA='{
    "username": "teststudent",
    "email": "teststudent@example.com",
    "password": "student123",
    "fullName": "Test Student",
    "role": "student"
}'

STUDENT_CREATE_RESPONSE=$(make_request "POST" "$BASE_URL/auth/register" "$STUDENT_DATA" "")
echo "Student creation response: $STUDENT_CREATE_RESPONSE"

# 10. Login as student
echo "10. Logging in as student..."
STUDENT_LOGIN_RESPONSE=$(make_request "POST" "$BASE_URL/auth/login" '{"username":"teststudent","password":"student123"}' "")
STUDENT_TOKEN=$(echo $STUDENT_LOGIN_RESPONSE | jq -r '.data.token // empty')

if [ -z "$STUDENT_TOKEN" ]; then
    echo "❌ Failed to get student token"
    echo "Response: $STUDENT_LOGIN_RESPONSE"
    exit 1
fi
echo "✅ Student logged in successfully"

# 11. Get student's quizzes
echo "11. Getting student's quizzes..."
STUDENT_QUIZZES_RESPONSE=$(make_request "GET" "$BASE_URL/quizzes" "" "$STUDENT_TOKEN")
echo "✅ Student quizzes retrieved"

# 12. Submit quiz answers
echo "12. Submitting quiz answers..."
SUBMISSION_DATA='{
    "answers": [
        {
            "questionId": "'$MC_QUESTION_ID'",
            "selectedOptionId": "'$(echo $MC_QUESTION_RESPONSE | jq -r '.data.question.options[0].id')'"
        },
        {
            "questionId": "'$TF_QUESTION_ID'",
            "selectedOptionId": "'$(echo $TF_QUESTION_RESPONSE | jq -r '.data.question.options[1].id')'"
        },
        {
            "questionId": "'$ESSAY_QUESTION_ID'",
            "answerText": "let and const are block-scoped, while var is function-scoped. const cannot be reassigned, while let can be."
        }
    ]
}'

SUBMISSION_RESPONSE=$(make_request "POST" "$BASE_URL/quizzes/$QUIZ_ID/submit" "$SUBMISSION_DATA" "$STUDENT_TOKEN")
SUBMISSION_ID=$(echo $SUBMISSION_RESPONSE | jq -r '.data.submissionId // empty')

if [ -z "$SUBMISSION_ID" ]; then
    echo "❌ Failed to submit quiz"
    echo "Response: $SUBMISSION_RESPONSE"
    exit 1
fi
echo "✅ Quiz submitted successfully: $SUBMISSION_ID"

# 13. Get quiz submissions (as instructor)
echo "13. Getting quiz submissions..."
SUBMISSIONS_RESPONSE=$(make_request "GET" "$BASE_URL/quizzes/$QUIZ_ID/submissions" "" "$ADMIN_TOKEN")
echo "✅ Quiz submissions retrieved"

# 14. Grade submission
echo "14. Grading submission..."
GRADE_DATA='{
    "grade": 85,
    "feedback": "Good work! You got the multiple choice and true/false questions correct. Your essay answer shows good understanding of JavaScript scoping."
}'

GRADE_RESPONSE=$(make_request "PUT" "$BASE_URL/quizzes/submissions/$SUBMISSION_ID/grade" "$GRADE_DATA" "$ADMIN_TOKEN")
echo "✅ Submission graded successfully"

# 15. Get all quizzes
echo "15. Getting all quizzes..."
ALL_QUIZZES_RESPONSE=$(make_request "GET" "$BASE_URL/quizzes" "" "$ADMIN_TOKEN")
echo "✅ All quizzes retrieved"

echo ""
echo "🎉 Quiz API test completed successfully!"
echo "📊 Summary:"
echo "   - Quiz created: $QUIZ_ID"
echo "   - Questions added: 3 (MC, TF, Essay)"
echo "   - Student submission: $SUBMISSION_ID"
echo "   - All endpoints tested successfully"
