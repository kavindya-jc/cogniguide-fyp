/// The student's "buddy": a cartoon profile picture they pick for fun.
///
/// It is a drawing, never a photo, so it says nothing about who the
/// student is. It is saved only on the phone (see SettingsStore.buddy).
enum Buddy {
  bolt,
  bookworm,
  bulb,
  cloudy,
  dino,
  jelly,
  kitty,
  mochi,
  pebble,
  pencil,
  rocket,
  sunny;

  /// The buddy's name, for example "Mochi". Names stay the same in every
  /// language, like a pet's name.
  String get label => name[0].toUpperCase() + name.substring(1);

  /// The picture file (from the designers' playful-ui-avatars set).
  String get asset => 'assets/avatars/avatar-$name.svg';

  /// Used until the student picks one.
  static const Buddy fallback = Buddy.mochi;
}
