import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/meeting_room.dart';

void main() {
  test('room name matches the web platform format (meeting-room.tsx)', () {
    expect(
      buildConsultationRoomName('7f3a9c12-0000-4000-8000-1234567890ab'),
      'PremonCare-7f3a9c12-0000-4000-8000-1234567890ab',
    );
  });

  test('room name is deterministic and contains the appointment id verbatim', () {
    const id = 'apt-42';
    expect(buildConsultationRoomName(id), 'PremonCare-$id');
    expect(buildConsultationRoomName(id), buildConsultationRoomName(id));
  });
}
