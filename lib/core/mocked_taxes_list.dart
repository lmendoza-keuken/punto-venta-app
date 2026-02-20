List<MockedTaxeModel> mockedTaxesList = [
  MockedTaxeModel(id: 1, description: 'IVA', percentage: 21.0),
  MockedTaxeModel(id: 2, description: 'IVA', percentage: 10.5),
  MockedTaxeModel(id: 3, description: 'REDUCIDO', percentage: 10.0),
];

class MockedTaxeModel {
  int id;
  String description;
  double percentage;

  MockedTaxeModel({
    required this.id,
    required this.description,
    required this.percentage,
  });
}
