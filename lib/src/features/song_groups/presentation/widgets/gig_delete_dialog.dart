import 'package:bandmole/l10n/app_localizations_fallback.dart';
import 'package:bandmole/l10n/generated/app_localizations.dart';
import 'package:bandmole/src/features/song_groups/domain/gig.dart';
import 'package:flutter/material.dart';

class GigDeleteDialog extends StatelessWidget {
  final Gig gig;

  const GigDeleteDialog({super.key, required this.gig});

  AppLocalizations _l10n(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      EnglishAppLocalizations();

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);

    return AlertDialog(
      title: Text('${l10n.deleteGig}: ${gig.title}?'),
      content: Text(l10n.deleteGigConfirmation),
      actions: [
        TextButton(
          key: const ValueKey<String>('cancel_delete_gig_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          key: const ValueKey<String>('confirm_delete_gig_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
