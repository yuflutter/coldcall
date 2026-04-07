import 'package:coldcall/app_config.dart';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/err.dart';
import 'package:coldcall/core/show_toastification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

/// Большинство ошибок мы показываем попапом поверх контента. Исключение - ошибки инициализации экрана или виджета,
/// которые мы показываем вместо контента, используя ErrorPresenter внутри FutureBuilder | SimpleFutureBuilder.
void showErrorPresenterPopup(BuildContext context, UserError userError) {
  if (context.mounted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: EdgeInsets.fromLTRB(10, 0, 10, 15),
        child: ErrorPresenter(userError: userError, howToCloseDialog: () => Navigator.pop(context)),
      ),
    );
  }
}

class ErrorPresenter extends StatefulWidget {
  const ErrorPresenter({super.key, required this.userError, this.howToCloseDialog});

  final UserError userError;
  final void Function()? howToCloseDialog;

  @override
  State<ErrorPresenter> createState() => _ErrorPresenterState();
}

class _ErrorPresenterState extends State<ErrorPresenter> {
  var _isDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Ошибка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Spacer(),
                      IconButton(icon: Icon(Icons.content_copy), onPressed: () => _copyToClipboard(context), tooltip: 'Copy'),
                      IconButton(icon: Icon(Icons.send), onPressed: () => _sendToSupport(), tooltip: 'Send to support'),
                      if (widget.howToCloseDialog != null)
                        IconButton(icon: Icon(Icons.close), onPressed: widget.howToCloseDialog, tooltip: 'Close'),
                    ],
                  ),
                  Gap(3),
                  if (!_isDetailsExpanded) ...{
                    SelectableText(widget.userError.short, style: TextStyle(fontSize: 17, color: Colors.red)),
                    Gap(7),
                    if (widget.userError.long != null)
                      InkWell(
                        onTap: () => setState(() => _isDetailsExpanded = true),
                        child: Container(alignment: Alignment.bottomRight, child: Text('Show details... ')),
                      ),
                  } else ...{
                    SelectableText(widget.userError.long!, style: TextStyle(fontSize: 17, color: Colors.red)),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // @override
  void _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.userError.long ?? widget.userError.short));
    if (context.mounted) showToastification(context, 'Скопировано');
  }

  // TODO: доделать кодировку, протестировать
  void _sendToSupport() {
    final url = 'mailto:${di<AppConfig>().supportEmail}?subject=ColdCall: ${widget.userError.long ?? widget.userError.short})';
    launchUrl(Uri.parse(url));
  }
}
