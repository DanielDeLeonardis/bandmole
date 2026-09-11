import 'package:bandmole/models/song.dart';
import 'package:bandmole/service/file_service.dart';
import 'package:bandmole/views/song_view.dart';
import 'package:bandmole/widgets/file_picker_widget.dart';
import 'package:bandmole/views/preferences_view.dart';
import 'package:flutter/material.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Search'), actions: [
        IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                (context),
                MaterialPageRoute(
                  builder: (context) => const PreferenceView(),
                ),
              );
            })
      ]),
      body: Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 10.0),
            MaterialButton(
              color: Colors.white,
              textColor: Colors.black,
              child: const Text('Open song'),
              onPressed: () async {
                final selectedFile = FilePicker().getFile();
                if (selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No song selected.'),
                    ),
                  );
                } else {
                  final Song song = await getSong(selectedFile);
                  if (context.mounted) {
                    if (song.text != null) {
                      if (song.isMalformed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Song contents has encoding issues. Please review.'),
                          ),
                        );
                      }
                      Navigator.push(
                        (context),
                        MaterialPageRoute(
                          builder: (context) => SongView(
                            text: song.text!,
                          ),
                        ),
                      );
                    } else {
                      if (song.isMalformed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Unable to load song. Check encoding is UTF-8.'),
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
