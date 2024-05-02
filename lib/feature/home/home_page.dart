// ignore_for_file: use_build_context_synchronously
import 'package:image_picker/image_picker.dart';
import 'package:ai_buddy/core/config/assets_constants.dart';
import 'package:ai_buddy/core/config/type_of_bot.dart';
import 'package:ai_buddy/core/extension/context.dart';
import 'package:ai_buddy/core/navigation/route.dart';
import 'package:ai_buddy/core/util/secure_storage.dart';
import 'package:ai_buddy/feature/chat/provider/message_provider.dart';
import 'package:ai_buddy/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:ai_buddy/feature/home/provider/chat_bot_provider.dart';
import 'package:ai_buddy/feature/home/widgets/widgets.dart';
import 'package:ai_buddy/feature/welcome/widgets/api_key_bottom_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:uuid/uuid.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final uuid = const Uuid();

  bool _isBuildingChatBot = false;
  String currentState = '';

  @override
  void initState() {
    super.initState();
    ref.read(chatBotListProvider.notifier).fetchChatBots();
  }

  Widget _buildLoadingIndicator(String currentState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitDoubleBounce(
            color: context.colorScheme.onSurface,
          ),
          const SizedBox(height: 8),
          Text(currentState, style: context.textTheme.titleMedium),
        ],
      ),
    );
  }

  void _showAllHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final chatBotsList = ref.watch(chatBotListProvider);
            return Column(
              children: [
                Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.separated(
                      itemCount: chatBotsList.length,
                      itemBuilder: (context, index) {
                        final chatBot = chatBotsList[index];
                        final imagePath = chatBot.typeOfBot == TypeOfBot.pdf
                            ? AssetConstants.pdfLogo
                            : chatBot.typeOfBot == TypeOfBot.image
                                ? AssetConstants.imageLogo
                                : AssetConstants.textLogo;
                        final tileColor = chatBot.typeOfBot == TypeOfBot.pdf
                            ? context.colorScheme.primary
                            : chatBot.typeOfBot == TypeOfBot.text
                                ? context.colorScheme.secondary
                                : context.colorScheme.tertiary;
                        return HistoryItem(
                          imagePath: imagePath,
                          label: chatBot.title,
                          color: tileColor,
                          chatBot: chatBot,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatBotsList = ref.watch(chatBotListProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _isBuildingChatBot
          ? _buildLoadingIndicator(currentState)
          : SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: -300,
                    top: -00,
                    child: Container(
                      height: 500,
                      width: 600,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            Theme.of(context)
                                .colorScheme
                                .background
                                .withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: BackgroundCurvesPainter(),
                    size: Size.infinite,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(
                              width: 60,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.25),
                                    offset: const Offset(4, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Powered by Gemini',
                                    style: TextStyle(
                                      color: context.colorScheme.background,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    AssetConstants.aiStarLogo,
                                    scale: 23,
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              maxRadius: 16,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.2),
                              child: IconButton(
                                icon: const Icon(
                                  CupertinoIcons.settings,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () async {
                                  final apiKey =
                                      await SecureStorage().getApiKey();
                                  final TextEditingController apiKeyController =
                                      TextEditingController(text: apiKey);
                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) {
                                      return APIKeyBottomSheet(
                                        apiKeyController: apiKeyController,
                                        isCalledFromHomePage: true,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Plant Disease\nDetector🌱',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: CardButton(
                                title: 'What Plant \nis this?',
                                color: context.colorScheme.primary,
                                imagePath: AssetConstants.pdfLogo,
                                isMainButton: true,
                                onPressed: () async {
                                  final pickedFile = await ref
                                      .read(chatBotListProvider.notifier)
                                      .captureImageFromCamera();
                                  if (pickedFile != null) {
                                    final chatBot = ChatBot(
                                      messagesList: [],
                                      id: uuid.v4(),
                                      title: '',
                                      typeOfBot: TypeOfBot.image,
                                      attachmentPath: pickedFile,
                                    );
                                    await ref
                                        .read(chatBotListProvider.notifier)
                                        .saveChatBot(chatBot);
                                    await ref
                                        .read(messageListProvider.notifier)
                                        .updateChatBot(chatBot);

                                    final prompt =
                                        "What is this plant tell me about it?";
                                    await ref
                                        .read(messageListProvider.notifier)
                                        .getGeminiResponse(
                                            prompt: prompt,
                                            imageFilePath: pickedFile);

                                    AppRoute.chat.push(context);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                children: [
                                  CardButton(
                                    title: 'Capture Image',
                                    color: context.colorScheme.tertiary,
                                    imagePath: AssetConstants.cameraLogo,
                                    isMainButton: false,
                                    onPressed: () async {
                                      final pickedFile = await ref
                                          .read(chatBotListProvider.notifier)
                                          .captureImageFromCamera();
                                      if (pickedFile != null) {
                                        final chatBot = ChatBot(
                                          messagesList: [],
                                          id: uuid.v4(),
                                          title: '',
                                          typeOfBot: TypeOfBot.image,
                                          attachmentPath: pickedFile,
                                        );
                                        await ref
                                            .read(chatBotListProvider.notifier)
                                            .saveChatBot(chatBot);
                                        await ref
                                            .read(messageListProvider.notifier)
                                            .updateChatBot(chatBot);

                                        final prompt =
                                            '''As a highly skilled plant pathologist, your expertise is indispensable in our pursuit of maintaining optimal plant health. You will be provided with information or samples related to plant diseases, and your role involves conducting a detailed analysis to identify the specific issues, propose solutions, and offer recommendations.
**Analysis Guidelines:**
1. **Disease Identification:** Examine the provided information or samples to identify and characterize plant diseases accurately.
2. **Detailed Findings:** Provide in-depth findings on the nature and extent of the identified plant diseases, including affected plant parts, symptoms, and potential causes.
3. **Next Steps:** Outline the recommended course of action for managing and controlling the identified plant diseases. This may involve treatment options, preventive measures, or further investigations.
4. **Recommendations:** Offer informed recommendations for maintaining plant health, preventing disease spread, and optimizing overall plant well-being.
5. **Important Note:** As a plant pathologist, your insights are vital for informed decision-making in agriculture and plant management. Your response should be thorough, concise, and focused on plant health.
**Disclaimer:**
*"Please note that the information provided is based on plant pathology analysis and should not replace professional agricultural advice. Consult with qualified agricultural experts before implementing any strategies or treatments."*
Your role is pivotal in ensuring the health and productivity of plants. Proceed to analyze the provided information or samples, adhering to the structured ''';
                                        await ref
                                            .read(messageListProvider.notifier)
                                            .getGeminiResponse(
                                                prompt: prompt,
                                                imageFilePath: pickedFile);

                                        AppRoute.chat.push(context);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  CardButton(
                                    title: 'Choose from \ngallery',
                                    color: context.colorScheme.tertiary,
                                    imagePath: AssetConstants.imageLogo,
                                    isMainButton: false,
                                    onPressed: () async {
                                      final pickedFile = await ref
                                          .read(chatBotListProvider.notifier)
                                          .attachImageFilePath();
                                      if (pickedFile != null) {
                                        final chatBot = ChatBot(
                                          messagesList: [],
                                          id: uuid.v4(),
                                          title: '',
                                          typeOfBot: TypeOfBot.image,
                                          attachmentPath: pickedFile,
                                        );
                                        await ref
                                            .read(chatBotListProvider.notifier)
                                            .saveChatBot(chatBot);
                                        await ref
                                            .read(messageListProvider.notifier)
                                            .updateChatBot(chatBot);

                                        final prompt =
                                            '''As a highly skilled plant pathologist, your expertise is indispensable in our pursuit of maintaining optimal plant health. You will be provided with information or samples related to plant diseases, and your role involves conducting a detailed analysis to identify the specific issues, propose solutions, and offer recommendations.
**Analysis Guidelines:**
1. **Disease Identification:** Examine the provided information or samples to identify and characterize plant diseases accurately.
2. **Detailed Findings:** Provide in-depth findings on the nature and extent of the identified plant diseases, including affected plant parts, symptoms, and potential causes.
3. **Next Steps:** Outline the recommended course of action for managing and controlling the identified plant diseases. This may involve treatment options, preventive measures, or further investigations.
4. **Recommendations:** Offer informed recommendations for maintaining plant health, preventing disease spread, and optimizing overall plant well-being.
5. **Important Note:** As a plant pathologist, your insights are vital for informed decision-making in agriculture and plant management. Your response should be thorough, concise, and focused on plant health.
Put these under each subtopic and make it viable to read and understand easily. Dont put give reponse like a report make it user-friendly like advising a farmer no ned of anything like best regards and all.
**Disclaimer:**
*"Please note that the information provided is based on plant pathology analysis and should not replace professional agricultural advice. Consult with qualified agricultural experts before implementing any strategies or treatments. ''';
                                        await ref
                                            .read(messageListProvider.notifier)
                                            .getGeminiResponse(
                                                prompt: prompt,
                                                imageFilePath: pickedFile);

                                        AppRoute.chat.push(context);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'History',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.95),
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showAllHistory(context),
                                    child: Text(
                                      'See all',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (chatBotsList.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(64),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const SizedBox(width: 12),
                                      Text(
                                        'No chats yet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withOpacity(0.95),
                                            ),
                                      ),
                                      const Icon(CupertinoIcons.cube_box),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: chatBotsList.length > 3
                                    ? 3
                                    : chatBotsList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final chatBot = chatBotsList[index];
                                  final imagePath =
                                      chatBot.typeOfBot == TypeOfBot.pdf
                                          ? AssetConstants.pdfLogo
                                          : chatBot.typeOfBot == TypeOfBot.image
                                              ? AssetConstants.imageLogo
                                              : AssetConstants.textLogo;
                                  final tileColor =
                                      chatBot.typeOfBot == TypeOfBot.pdf
                                          ? context.colorScheme.primary
                                          : chatBot.typeOfBot == TypeOfBot.text
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .tertiary;
                                  return HistoryItem(
                                    label: chatBot.title,
                                    imagePath: imagePath,
                                    color: tileColor,
                                    chatBot: chatBot,
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
