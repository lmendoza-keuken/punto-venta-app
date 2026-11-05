class CreateDisposeReasonRequestModel {
  final String code;
  final String description;

  const CreateDisposeReasonRequestModel({
    required this.code,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
      };
}
