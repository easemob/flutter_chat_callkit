class Config {
  static String agoraAppId = "15cb0d28b87b425ea613fc46f7c9f974";
  static String appkey = "41117440#383391";

  static String appServerDomain = "a41.easemob.com";

  static String appServerRegister = 'app/chat/user/register';
  static String appServerGetAgoraToken = 'app/chat/user/login';

  /// call token : http://a41.easemob.com/token/rtc/channel/"channel_name"/agorauid/"uid"?userAccount="account"
  static String appServerTokenURL = "token/rtc/channel";

  /// mapper:  http://a41.easemob.com/agora/channel/mapper?channelName="channel_name"$userAccount=userId
  static String appServerUserMapperURL = "agora/channel/mapper";
}
