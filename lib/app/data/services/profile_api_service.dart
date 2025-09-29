import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/profile_model.dart';
import 'dart:io';

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
