import 'package:flutter/material.dart';
import 'package:full_screen_image/full_screen_image.dart';

class AttachmentFullScreenViewer extends StatefulWidget {
  final String attachments;

  AttachmentFullScreenViewer({required this.attachments});

  @override
  State<AttachmentFullScreenViewer> createState() =>
      _AttachmentFullScreenViewerState();
}

class _AttachmentFullScreenViewerState
    extends State<AttachmentFullScreenViewer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FullScreenWidget(
        backgroundIsTransparent: false,
        disposeLevel: DisposeLevel.Low,
        child: Image.network(
          widget.attachments,
          fit: BoxFit.fill,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
