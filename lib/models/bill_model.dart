class BillItem {
  String name;
  int quantity;
  double pricePerUnit;
  double totalPrice;
  List<String> assignedTo;

  BillItem({
    required this.name,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.assignedTo,
  }) {
    pricePerUnit = pricePerUnit > 0 ? pricePerUnit : 0.0;
    totalPrice = totalPrice > 0 ? totalPrice : 0.0;
    
    pricePerUnit = double.parse(pricePerUnit.toStringAsFixed(2));
    totalPrice = double.parse(totalPrice.toStringAsFixed(2));
  }

  BillItem copyWith({
    String? name,
    int? quantity,
    double? pricePerUnit,
    double? totalPrice,
    List<String>? assignedTo,
  }) {
    return BillItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalPrice: totalPrice ?? this.totalPrice,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  factory BillItem.empty() {
    return BillItem(
      name: '',
      quantity: 1,
      pricePerUnit: 0.0,
      totalPrice: 0.0,
      assignedTo: [],
    );
  }
}

class Participant {
  String id;
  String name;
  String phoneNumber;

  Participant({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
    );
  }
}

class BillData {
  List<BillItem> items;
  List<Participant> participants;
  String? receiptImagePath;
  DateTime createdDate;

  BillData({
    required this.items,
    required this.participants,
    this.receiptImagePath,
    required this.createdDate,
  });

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Map<String, double> calculateSplit() {
    Map<String, double> result = {};

    for (var participant in participants) {
      result[participant.id] = 0;
    }

    for (var item in items) {
      if (item.assignedTo.isNotEmpty) {
        double pricePerPerson = item.totalPrice / item.assignedTo.length;
        for (var participantId in item.assignedTo) {
          result[participantId] = (result[participantId] ?? 0) + pricePerPerson;
        }
      }
    }

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => {
        'name': item.name,
        'quantity': item.quantity,
        'pricePerUnit': item.pricePerUnit,
        'totalPrice': item.totalPrice,
        'assignedTo': item.assignedTo,
      }).toList(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'receiptImagePath': receiptImagePath,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory BillData.fromMap(Map<String, dynamic> map) {
    return BillData(
      items: List<BillItem>.from(map['items'].map((item) => BillItem(
        name: item['name'],
        quantity: item['quantity'],
        pricePerUnit: item['pricePerUnit'],
        totalPrice: item['totalPrice'],
        assignedTo: List<String>.from(item['assignedTo']),
      ))),
      participants: List<Participant>.from(
        map['participants'].map((p) => Participant.fromMap(p))
      ),
      receiptImagePath: map['receiptImagePath'],
      createdDate: DateTime.parse(map['createdDate']),
    );
  }
}