class AppRoutes {
  static const login = '/login';
  static const splash = '/splash';
  static const dashboard = '/'; // Keep dashboard as the root (Action Hub)
  static const actionHub = '/action-hub';
  static const growth = '/growth';
  static const engagement = '/engagement';
  static const users = '/users';
  static const String verification = '/verification';
  static const String moderation = '/moderation';
  static const String supportChats = '/support-chats';
  static const String supportChatDetail = '/support-chat/:id';
  static const settings = '/settings';
  static const manageAdmins = '/manage-admins';

  static String userDetail(String id, {String mode = 'manage'}) => '/user/$id?mode=$mode';
  static String storyDetail(String id, {String mode = 'manage'}) => '/story/$id?mode=$mode';
  static String supportChat(String id) => '/support-chat/$id';
  static const notAuthorized = '/notAuthorized';
}
