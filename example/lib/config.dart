class Config {
  static String agoraAppId = "15cb0d28b87b425ea613fc46f7c9f974";
  static String appkey = "41117440#383391";

  static String appServerDomain = "a41.easemob.com";

  static String appServerRegister = 'app/chat/user/register';
  static String appServerGetAgoraToken = 'app/chat/user/login';

  static String appServerTokenURL = "token/rtc/channel";
  static String appServerUserMapperURL = "agora/channel/mapper";


  // call token : http://a41.easemob.com/token/rtc/channel/"33333"/agoraUid/"uid"?userAccount="account"
  // mapper:  http://a41.easemob.com/agora/channel/mapper?channelName="111"$userAccount=userId
}
