import 'package:flutter/material.dart';

import '../../models/public_event.dart';
import 'event_experience_screen.dart';
import 'generic_event_screen.dart';

void openPublicEvent(BuildContext context, PublicEvent event) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => event.hasEventApp
          ? EventExperienceScreen(event: event)
          : GenericEventScreen(event: event),
    ),
  );
}
