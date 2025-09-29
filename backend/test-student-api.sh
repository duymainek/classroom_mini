#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3131"

echo -e "${BLUE}🧪 Testing Student Management API${NC}"
echo "=================================="

# Step 1: Login as Instructor
echo -e "\n${YELLOW}1. Instructor Login...${NC}"
INSTRUCTOR_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/instructor/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}')

echo "$INSTRUCTOR_RESPONSE" | jq '.'

ACCESS_TOKEN=$(echo "$INSTRUCTOR_RESPONSE" | jq -r '.data.tokens.accessToken // empty')

if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    echo -e "${GREEN}✅ Instructor login successful${NC}"
    
    # Step 2: Get Student Statistics
    echo -e "\n${YELLOW}2. Get Student Statistics...${NC}"
    curl -s -X GET "$BASE_URL/api/students/statistics" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Step 3: Create Multiple Students
    echo -e "\n${YELLOW}3. Creating Students...${NC}"
    
    # Create Student 1
    echo -e "\n${BLUE}3.1. Creating Student 1 (Vietnamese name)...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "nguyenvana",
        "password": "student123",
        "email": "nguyenvana@test.com",
        "fullName": "Nguyễn Văn A"
      }' | jq '.'
    
    # Create Student 2
    echo -e "\n${BLUE}3.2. Creating Student 2...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "tranthib",
        "password": "student456",
        "email": "tranthib@test.com",
        "fullName": "Trần Thị B"
      }' | jq '.'
    
    # Create Student 3
    echo -e "\n${BLUE}3.3. Creating Student 3...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "levanc",
        "password": "student789",
        "email": "levanc@test.com",
        "fullName": "Lê Văn C"
      }' | jq '.'
    
    # Step 4: Get All Students with Pagination
    echo -e "\n${YELLOW}4. Get Students (Page 1)...${NC}"
    curl -s -X GET "$BASE_URL/api/students?page=1&limit=5" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Step 5: Search Students
    echo -e "\n${YELLOW}5. Search Students...${NC}"
    
    echo -e "\n${BLUE}5.1. Search by name 'Nguyễn'...${NC}"
    curl -s -X GET "$BASE_URL/api/students?search=Nguyễn" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    echo -e "\n${BLUE}5.2. Search by username 'tran'...${NC}"
    curl -s -X GET "$BASE_URL/api/students?search=tran" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Step 6: Filter by Status
    echo -e "\n${YELLOW}6. Filter Students by Status...${NC}"
    
    echo -e "\n${BLUE}6.1. Get Active Students...${NC}"
    curl -s -X GET "$BASE_URL/api/students?status=active" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Step 7: Sort Students
    echo -e "\n${YELLOW}7. Sort Students...${NC}"
    
    echo -e "\n${BLUE}7.1. Sort by created_at ASC...${NC}"
    curl -s -X GET "$BASE_URL/api/students?sortBy=created_at&sortOrder=asc" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    echo -e "\n${BLUE}7.2. Sort by full_name ASC...${NC}"
    curl -s -X GET "$BASE_URL/api/students?sortBy=full_name&sortOrder=asc" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Step 8: Get Student Statistics After Creation
    echo -e "\n${YELLOW}8. Get Updated Statistics...${NC}"
    STATS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/students/statistics" \
      -H "Authorization: Bearer $ACCESS_TOKEN")
    echo "$STATS_RESPONSE" | jq '.'
    
    # Step 9: Test Student Login
    echo -e "\n${YELLOW}9. Test Student Login...${NC}"
    STUDENT_LOGIN=$(curl -s -X POST "$BASE_URL/api/auth/student/login" \
      -H "Content-Type: application/json" \
      -d '{"username": "nguyenvana", "password": "student123"}')
    
    echo "$STUDENT_LOGIN" | jq '.'
    
    STUDENT_TOKEN=$(echo "$STUDENT_LOGIN" | jq -r '.data.tokens.accessToken // empty')
    
    if [ -n "$STUDENT_TOKEN" ] && [ "$STUDENT_TOKEN" != "null" ]; then
        echo -e "${GREEN}✅ Student login successful${NC}"
        
        # Test Student trying to access management (should fail)
        echo -e "\n${YELLOW}10. Test Student Access Control (Should Fail)...${NC}"
        curl -s -X GET "$BASE_URL/api/students" \
          -H "Authorization: Bearer $STUDENT_TOKEN" | jq '.'
    else
        echo -e "${RED}❌ Student login failed${NC}"
    fi
    
    # Step 11: Test Validation Errors
    echo -e "\n${YELLOW}11. Test Validation Errors...${NC}"
    
    echo -e "\n${BLUE}11.1. Invalid Vietnamese name...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "testuser",
        "password": "test123",
        "email": "test@test.com",
        "fullName": "Test123!@#"
      }' | jq '.'
    
    echo -e "\n${BLUE}11.2. Duplicate username...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "nguyenvana",
        "password": "test123",
        "email": "duplicate@test.com",
        "fullName": "Duplicate User"
      }' | jq '.'
    
    echo -e "\n${BLUE}11.3. Invalid email format...${NC}"
    curl -s -X POST "$BASE_URL/api/students" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -d '{
        "username": "validuser",
        "password": "test123",
        "email": "invalid-email",
        "fullName": "Valid User"
      }' | jq '.'
    
    # Step 12: Test Export (placeholder)
    echo -e "\n${YELLOW}12. Test Export Students...${NC}"
    curl -s -X GET "$BASE_URL/api/students/export?format=csv" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
    # Step 13: Health Check
    echo -e "\n${YELLOW}13. Student Service Health Check...${NC}"
    curl -s -X GET "$BASE_URL/api/students/health" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.'
    
else
    echo -e "${RED}❌ Instructor login failed${NC}"
fi

echo -e "\n${GREEN}🎉 Student Management API Testing Complete!${NC}"