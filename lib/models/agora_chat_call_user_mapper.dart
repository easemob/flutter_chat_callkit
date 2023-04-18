/// User information Mapper, used to obtain the mapping between agoraUid and userId.
class AgoraChatCallUserMapper {
  const AgoraChatCallUserMapper(this.channel, this.infoMapper);

  /// rtc channel
  final String channel;

  /// agoraUid and userId map. key is agoraUid, value is userId.
  final Map<int, String> infoMapper;
}
