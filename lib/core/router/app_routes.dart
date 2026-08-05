class AppRoutes {
  static const login = '/login';
  static const splash = '/splash';
  static const dashboard = '/';
  static const users = '/users';
  static const verification = '/verification';
  static const moderation = '/moderation';
  static const settings = '/settings';
  static const manageAdmins = '/manage-admins';

  static String userDetail(String id, {String mode = 'manage'}) => '/user/$id?mode=$mode';
  static String storyDetail(String id, {String mode = 'manage'}) => '/story/$id?mode=$mode';
  static const notAuthorized = '/notAuthorized';
}
