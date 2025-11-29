import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:classroom_mini/app/data/models/request/profile_request.dart';
import 'package:classroom_mini/app/data/models/response/profile_response.dart';
import 'dart:io'
    if (dart.library.html) 'package:classroom_mini/app/shared/controllers/io_stub.dart';

part 'profile_api_service.g.dart';

@RestApi()
abstract class ProfileApiService {
  factory ProfileApiService(Dio dio, {String baseUrl}) = _ProfileApiService;

  @GET('/profile')
  Future<ProfileResponse> getProfile();

  @PUT('/profile')
  Future<ProfileResponse> updateProfile(@Body() UpdateProfileRequest request);

  @POST('/profile/avatar')
  @MultiPart()
  Future<AvatarUploadResponse> uploadAvatar(@Part(name: 'avatar') File avatar);
}
