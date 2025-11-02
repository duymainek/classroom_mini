import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:classroom_mini/app/data/models/request/quiz_request.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';

part 'quiz_api_service.g.dart';

@RestApi()
abstract class QuizApiService {
  factory QuizApiService(Dio dio, {String baseUrl}) = _QuizApiService;

  @POST('/quizzes')
  Future<QuizCreateResponse> createQuiz(@Body() QuizCreateRequest request);

  @GET('/quizzes')
  Future<QuizListResponse> getQuizzes({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('search') String search = '',
    @Query('courseId') String courseId = '',
    @Query('semesterId') String semesterId = '',
    @Query('status') String status = 'all',
    @Query('sortBy') String sortBy = 'created_at',
    @Query('sortOrder') String sortOrder = 'desc',
  });

  @GET('/quizzes/{quizId}')
  Future<QuizSingleResponse> getQuizById(@Path('quizId') String quizId);

  @PUT('/quizzes/{quizId}')
  Future<QuizSingleResponse> updateQuiz(
    @Path('quizId') String quizId,
    @Body() QuizUpdateRequest request,
  );

  @DELETE('/quizzes/{quizId}')
  Future<void> deleteQuiz(@Path('quizId') String quizId);

  @POST('/quizzes/{quizId}/questions')
  Future<QuizQuestionSingleResponse> addQuestion(
    @Path('quizId') String quizId,
    @Body() QuestionCreateRequest request,
  );

  @PUT('/quizzes/{quizId}/questions/{questionId}')
  Future<QuizQuestionSingleResponse> updateQuestion(
    @Path('quizId') String quizId,
    @Path('questionId') String questionId,
    @Body() QuestionUpdateRequest request,
  );

  @DELETE('/quizzes/{quizId}/questions/{questionId}')
  Future<void> deleteQuestion(
    @Path('quizId') String quizId,
    @Path('questionId') String questionId,
  );
}
