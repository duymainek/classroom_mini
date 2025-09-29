#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3131"

echo -e "${YELLOW}🧪 Testing Classroom Mini Backend API${NC}"
echo "=================================="

# Test 1: Health Check
echo -e "\n${YELLOW}1. Testing Health Check...${NC}"
curl -s "$BASE_URL/health" | jq '.'

# Test 2: Auth Test Endpoint
echo -e "\n${YELLOW}2. Testing Auth Routes Info...${NC}"
curl -s "$BASE_URL/api/auth/test" | jq '.'

# Test 3: Instructor Login
echo -e "\n${YELLOW}3. Testing Instructor Login...${NC}"
INSTRUCTOR_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/instructor/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}')

echo "$INSTRUCTOR_RESPONSE" | jq '.'

# Extract access token for further tests
ACCESS_TOKEN=$(echo "$INSTRUCTOR_RESPONSE" | jq -r '.data.tokens.accessToken // empty')

if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    echo -e "${GREEN}✅ Instructor login successful${NC}"
    
    # Test 4: Get Current User
    echo -e "\n${YELLOW}4. Testing Get Current User...${NC}"
    curl -s -X GET "$BASE_URL/api/auth/me" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Test 5: Create Student (New API)
    echo -e "\n${YELLOW}5. Testing Create Student (New API)...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "teststudent",
        "password": "student123",
        "email": "test@student.com",
        "fullName": "Nguyễn Văn Test"
      }' | jq '.'
    
    # Test 6: Get All Students (New API with pagination)
    echo -e "\n${YELLOW}6. Testing Get All Students (New API)...${NC}"
    curl -s -X GET "$BASE_URL/api/students?page=1&limit=10" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Test 6.1: Get Student Statistics
    echo -e "\n${YELLOW}6.1. Testing Get Student Statistics...${NC}"
    curl -s -X GET "$BASE_URL/api/students/statistics" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Test 6.2: Search Students
    echo -e "\n${YELLOW}6.2. Testing Search Students...${NC}"
    curl -s -X GET "$BASE_URL/api/students?search=test&status=active" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Test 7: Student Login
    echo -e "\n${YELLOW}7. Testing Student Login...${NC}"
    STUDENT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/student/login" \
      -H "Content-Type: application/json" \
      -d '{"username": "teststudent", "password": "student123"}')
    
    echo "$STUDENT_RESPONSE" | jq '.'
    
    STUDENT_TOKEN=$(echo "$STUDENT_RESPONSE" | jq -r '.data.tokens.accessToken // empty')
    
    if [ -n "$STUDENT_TOKEN" ] && [ "$STUDENT_TOKEN" != "null" ]; then
        echo -e "${GREEN}✅ Student login successful${NC}"
        
        # Test 8: Student Get Profile
        echo -e "\n${YELLOW}8. Testing Student Get Profile...${NC}"
        curl -s -X GET "$BASE_URL/api/auth/me" \
          -H "Authorization: Bearer $STUDENT_TOKEN" | jq '.'
        
        # Test 9: Student Try to Access Student Management (Should Fail)
        echo -e "\n${YELLOW}9. Testing Student Authorization (Should Fail)...${NC}"
        curl -s -X GET "$BASE_URL/api/students" \
          -H "Authorization: Bearer $STUDENT_TOKEN" | jq '.'
        
        # Test 9.1: Test Bulk Operations (Instructor Only)
        echo -e "\n${YELLOW}9.1. Testing Bulk Operations...${NC}"
        curl -s -X POST "$BASE_URL/api/students/bulk" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $ACCESS_TOKEN" \
          -d '{
            "studentIds": ["dummy-uuid"],
            "action": "activate"
          }' | jq '.'
        
    else
        echo -e "${RED}❌ Student login failed${NC}"
    fi
    
else
    echo -e "${RED}❌ Instructor login failed${NC}"
fi

# Test 10: Invalid Login
echo -e "\n${YELLOW}10. Testing Invalid Login (Should Fail)...${NC}"
curl -s -X POST "$BASE_URL/api/auth/instructor/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "wrongpassword"}' | jq '.'

echo -e "\n${GREEN}🎉 API Testing Complete!${NC}"