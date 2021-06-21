import 'package:flutter/material.dart';

class BalanceProperty {
  int amount; // in cents

  BalanceProperty({@required this.amount});

  factory BalanceProperty.fromJson(Map json) {
    if (json == null) {
      return null;
    }
    return BalanceProperty(amount: json["amount"]);
  }
}

class Balance {
  final BalanceProperty waitingFunds;
  final BalanceProperty available;
  final BalanceProperty transfered;

  Balance({
    @required this.waitingFunds,
    @required this.available,
    @required this.transfered,
  });

  factory Balance.fromJson(Map json) {
    print(json);
    print(json["waiting_funds"]);
    return json == null
        ? null
        : Balance(
            waitingFunds: BalanceProperty.fromJson(json["waiting_funds"]),
            available: BalanceProperty.fromJson(json["available"]),
            transfered: BalanceProperty.fromJson(json["transfered"]),
          );
  }
}

enum TransferType {
  ted,
  doc,
  creditoEmConta,
}

extension TransferTypeExtension on TransferType {
  static TransferType fromString(String s) {
    switch (s) {
      case "ted":
        return TransferType.ted;
      case "doc":
        return TransferType.doc;
      case "credito_em_conta":
        return TransferType.creditoEmConta;
      default:
        return null;
    }
  }
}

enum TransferStatus {
  pendingTransfer,
  transferred,
  failed,
  processing,
  canceled,
}

extension TransferStatusExtension on TransferStatus {
  static TransferStatus fromString(String s) {
    switch (s) {
      case "pending_transfer":
        return TransferStatus.pendingTransfer;
      case "transferred":
        return TransferStatus.transferred;
      case "failed":
        return TransferStatus.failed;
      case "processing":
        return TransferStatus.processing;
      case "canceled":
        return TransferStatus.canceled;
      default:
        return null;
    }
  }
}

class Transfer {
  int id;
  int amount;
  TransferType type;
  TransferStatus status;
  int fee;
  int fundingDate;
  int fundingEstimatedDate;
  int transactionID;

  Transfer({
    @required this.id,
    @required this.amount,
    @required this.type,
    @required this.status,
    @required this.fee,
    @required this.fundingDate,
    @required this.fundingEstimatedDate,
    @required this.transactionID,
  });

  factory Transfer.fromJson(Map json) {
    if (json == null) {
      return null;
    }

    TransferType type = TransferTypeExtension.fromString(json["type"]);
    TransferStatus status = TransferStatusExtension.fromString(json["status"]);

    return Transfer(
      id: json["id"],
      amount: json["amount"],
      type: type,
      status: status,
      fee: json["fee"],
      fundingDate: json["funding_date"],
      fundingEstimatedDate: json["funding_estimated_date"],
      transactionID: json["transaction_id"],
    );
  }
}
