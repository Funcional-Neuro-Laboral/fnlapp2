class TestNotice {
  final int afterQuestion;
  final String? title;
  final String description;
  final String? imagePath;
  final String buttonText;

  TestNotice({
    required this.afterQuestion,
    this.title,
    required this.description,
    this.imagePath,
    this.buttonText = 'Continuar',
  });
}
