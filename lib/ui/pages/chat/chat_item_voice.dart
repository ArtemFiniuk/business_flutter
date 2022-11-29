import 'dart:io';
import 'dart:math';

import 'package:chat_babakcode/constants/app_constants.dart';
import 'package:chat_babakcode/constants/config.dart';
import 'package:chat_babakcode/providers/global_setting_provider.dart';
import 'package:chat_babakcode/ui/widgets/app_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_babakcode/models/chat.dart';
import 'package:chat_babakcode/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart' as intl;
import '../../../providers/chat_provider.dart';
import '../../widgets/app_text.dart';

class ChatItemVoice extends StatefulWidget {
  final bool fromMyAccount;
  final ChatVoiceModel chat;

  const ChatItemVoice(this.fromMyAccount, {Key? key, required this.chat})
      : super(key: key);

  @override
  State<ChatItemVoice> createState() => _ChatItemVoiceState();
}

class _ChatItemVoiceState extends State<ChatItemVoice>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  final random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var _widthChatPageSection = MediaQuery.of(context).size.width;
    if (_widthChatPageSection > 960) {
      _widthChatPageSection -= 260;
    }
    if (_widthChatPageSection > 600) {
      _widthChatPageSection -= 340;
    }
    final auth = context.read<Auth>();
    final globalSetting = context.watch<GlobalSettingProvider>();

    return Column(
      crossAxisAlignment: widget.chat.user!.id == auth.myUser?.id
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _widthChatPageSection > 400 ? 360 : _widthChatPageSection * .8,
          child: Row(
            children: [
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: globalSetting.isDarkTheme
                    ? AppConstants.textColor
                    : AppConstants.textColor[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusCircular),
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: FutureBuilder<Directory>(
                    future: getApplicationDocumentsDirectory(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        String fullPath =
                            "${snapshot.data!.path}/${widget.chat.fileUrl.split('/').last}";
                        bool exist = File(fullPath).existsSync();
                        return Consumer<ChatProvider>(
                            builder: (context, chatProvider, child) {
                          if (widget.chat.downloadProgress != null &&
                              widget.chat.downloadProgress! < 99) {
                            return CircularProgressIndicator(
                              value: widget.chat.downloadProgress! / 100,
                            );
                          }
                          return IconButton(
                            onPressed: () async {
                              if (exist == false) {
                                chatProvider.downloadImage(
                                    widget.chat.fileUrl, fullPath, widget.chat);
                              } else {
                                widget.chat.isPlaying = true;
                                chatProvider.notifyListeners();
                                await widget.chat.audioPlayer
                                    .setFilePath(fullPath);
                                _controller.forward();
                                _controller.repeat();
                                await widget.chat.audioPlayer.play();
                                await widget.chat.audioPlayer.pause();
                                _controller.stop();
                                widget.chat.isPlaying = false;
                                chatProvider.notifyListeners();
                              }
                            },
                            icon: exist
                                ? widget.chat.isPlaying
                                    ? const Icon(Icons.pause_rounded)
                                    : const Icon(Icons.play_arrow_rounded)
                                : const Icon(Icons.download_rounded),
                          );
                        });
                      }
                      return const CircularProgressIndicator();
                    }),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AppText(
                        widget.chat.user!.name!,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                      ),
                    ),
                    !kIsWeb
                        ? Lottie.asset(
                            'assets/json/equalizer_${globalSetting.isDarkTheme ? 'light' : 'dark'}.json',
                            width: double.infinity,
                            height: 36,
                            controller: _controller, onLoaded: (composition) {
                            _controller
                              ..duration = composition.duration
                              ..value = random.nextInt(100) / 100;
                          }, animate: false, repeat: true, fit: BoxFit.fill)
                        : AppText(widget.chat.fileUrl, maxLines: 1, size: 12),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.bottomRight,
                      child: Text(
                        intl.DateFormat('HH:mm')
                            .format(widget.chat.utcDate!)
                            .toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}