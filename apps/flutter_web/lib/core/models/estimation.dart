import 'package:intl/intl.dart';

enum PackageTier { economy, standard, premium }
enum EstimateStatus { draft, pendingApproval, approved, rejected, active, archived }
enum UserRole { siteCoordinator, estimator, admin, superadmin, managingDirector }

class ProjectClientInfo {
  String projectId;
  String clientName;
  String clientContact; // phone/email, validated
  String projectType; // e.g. Residential, Commercial, Renovation
  double builtUpAreaSqFt; // > 0, required
  String? floorPlanFileUrl; // uploaded PDF/image
  Map<String, double>? aiExtractedAreas; // {"livingRoom": 220.5, ...}
  DateTime createdAt;

  ProjectClientInfo({
    required this.projectId,
    required this.clientName,
    required this.clientContact,
    required this.projectType,
    required this.builtUpAreaSqFt,
    this.floorPlanFileUrl,
    this.aiExtractedAreas,
    required this.createdAt,
  });

  factory ProjectClientInfo.fromJson(Map<String, dynamic> json) {
    Map<String, double>? extracted;
    if (json['aiExtractedAreas'] != null) {
      extracted = (json['aiExtractedAreas'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, double.tryParse(value.toString()) ?? 0.0),
      );
    }
    return ProjectClientInfo(
      projectId: json['projectId'] ?? '',
      clientName: json['clientName'] ?? '',
      clientContact: json['clientContact'] ?? '',
      projectType: json['projectType'] ?? 'Residential',
      builtUpAreaSqFt: double.tryParse(json['builtUpArea']?.toString() ?? json['builtUpAreaSqFt']?.toString() ?? '0.0') ?? 0.0,
      floorPlanFileUrl: json['floorPlanFileUrl'],
      aiExtractedAreas: extracted,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'clientName': clientName,
      'clientContact': clientContact,
      'projectType': projectType,
      'builtUpArea': builtUpAreaSqFt,
      'floorPlanFileUrl': floorPlanFileUrl,
      'aiExtractedAreas': aiExtractedAreas,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MaterialRate {
  String materialId;
  String name; // Cement, Steel, Bricks, Sand, Aggregate, Paint, etc.
  String unit; // bag, ton, sq.ft, cu.ft
  double baseRate; // currency per unit
  double quantityRatioPerSqFt; // consumption ratio used to derive quantity
  PackageTier tier;
  String region;
  double? previousRate; // for trend arrow calculation
  DateTime lastUpdated;

  MaterialRate({
    required this.materialId,
    required this.name,
    required this.unit,
    required this.baseRate,
    required this.quantityRatioPerSqFt,
    required this.tier,
    required this.region,
    this.previousRate,
    required this.lastUpdated,
  });

  factory MaterialRate.fromJson(Map<String, dynamic> json) {
    String tierStr = (json['tier'] ?? json['selectedPackage'] ?? 'standard').toString().toLowerCase();
    PackageTier tierVal = PackageTier.standard;
    if (tierStr == 'economy') tierVal = PackageTier.economy;
    if (tierStr == 'premium') tierVal = PackageTier.premium;

    return MaterialRate(
      materialId: json['id']?.toString() ?? json['materialId']?.toString() ?? '',
      name: json['materialName'] ?? json['name'] ?? '',
      unit: json['unit'] ?? '',
      baseRate: double.tryParse(json['currentRate']?.toString() ?? json['baseRate']?.toString() ?? json['rate']?.toString() ?? '0.0') ?? 0.0,
      quantityRatioPerSqFt: double.tryParse(json['quantityRatioPerSqFt']?.toString() ?? '0.0') ?? 0.0,
      tier: tierVal,
      region: json['district'] ?? json['region'] ?? '',
      previousRate: json['previousRate'] != null ? double.tryParse(json['previousRate'].toString()) : null,
      lastUpdated: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': materialId,
      'materialName': name,
      'unit': unit,
      'currentRate': baseRate,
      'quantityRatioPerSqFt': quantityRatioPerSqFt,
      'tier': tier.name,
      'district': region,
      'previousRate': previousRate,
      'updatedAt': lastUpdated.toIso8601String(),
    };
  }
}

class BOQItem {
  String itemId;
  String description;
  String unit;
  double quantity;
  double rate;
  double get amount => quantity * rate; // Derived, read-only
  String category; // Civil, Electrical, Plumbing, Finishing, etc.

  BOQItem({
    required this.itemId,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.rate,
    required this.category,
  });

  factory BOQItem.fromJson(Map<String, dynamic> json) {
    return BOQItem(
      itemId: json['id']?.toString() ?? json['itemId']?.toString() ?? '',
      description: json['materialName'] ?? json['description'] ?? '',
      unit: json['unit'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0.0') ?? 0.0,
      rate: double.tryParse(json['rate']?.toString() ?? '0.0') ?? 0.0,
      category: json['category'] ?? 'Civil',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': itemId,
      'materialName': description,
      'unit': unit,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'category': category,
    };
  }
}

class PhaseMilestone {
  String phaseId;
  String name; // Foundation, Structure, Brickwork, Finishing, etc.
  int durationDays;
  double costTarget;
  DateTime? startDate;
  DateTime? get endDate => startDate != null ? startDate!.add(Duration(days: durationDays)) : null; // Derived
  double percentOfTotalBudget;

  PhaseMilestone({
    required this.phaseId,
    required this.name,
    required this.durationDays,
    required this.costTarget,
    this.startDate,
    required this.percentOfTotalBudget,
  });

  factory PhaseMilestone.fromJson(Map<String, dynamic> json) {
    return PhaseMilestone(
      phaseId: json['id']?.toString() ?? json['phaseId']?.toString() ?? '',
      name: json['phaseName'] ?? json['name'] ?? '',
      durationDays: int.tryParse(json['estimatedDuration']?.toString() ?? '0') ?? 0,
      costTarget: double.tryParse(json['estimatedCost']?.toString() ?? json['costTarget']?.toString() ?? '0.0') ?? 0.0,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      percentOfTotalBudget: double.tryParse(json['percentOfTotalBudget']?.toString() ?? json['budgetAllocation']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': phaseId,
      'phaseName': name,
      'estimatedDuration': durationDays,
      'estimatedCost': costTarget,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budgetAllocation': percentOfTotalBudget,
    };
  }
}

class LabourEntry {
  String labourId;
  String trade; // Mason, Carpenter, Helper, etc.
  int count;
  double dailyWage;
  int estimatedDays;
  double get totalCost => count * dailyWage * estimatedDays; // Derived

  LabourEntry({
    required this.labourId,
    required this.trade,
    required this.count,
    required this.dailyWage,
    required this.estimatedDays,
  });

  factory LabourEntry.fromJson(Map<String, dynamic> json) {
    return LabourEntry(
      labourId: json['id']?.toString() ?? json['labourId']?.toString() ?? '',
      trade: json['labourType'] ?? json['trade'] ?? '',
      count: int.tryParse(json['requiredWorkers']?.toString() ?? json['count']?.toString() ?? '0') ?? 0,
      dailyWage: double.tryParse(json['dailyWage']?.toString() ?? '850.0') ?? 850.0,
      estimatedDays: int.tryParse(json['estimatedDays']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': labourId,
      'labourType': trade,
      'requiredWorkers': count,
      'dailyWage': dailyWage,
      'estimatedDays': estimatedDays,
      'estimatedCost': totalCost,
    };
  }
}

class ProfitMarginConfig {
  double marginPercent; // e.g. 12.5
  double overheadBufferPercent; // e.g. 5.0
  double contingencyPercent; // default 0

  ProfitMarginConfig({
    required this.marginPercent,
    required this.overheadBufferPercent,
    this.contingencyPercent = 0.0,
  });

  factory ProfitMarginConfig.fromJson(Map<String, dynamic> json) {
    return ProfitMarginConfig(
      marginPercent: double.tryParse(json['profitMarginPercentage']?.toString() ?? json['marginPercent']?.toString() ?? '12.0') ?? 12.0,
      overheadBufferPercent: double.tryParse(json['companyOverheadPercent']?.toString() ?? json['overheadBufferPercent']?.toString() ?? '5.0') ?? 5.0,
      contingencyPercent: double.tryParse(json['contingencyPercent']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profitMarginPercentage': marginPercent,
      'companyOverheadPercent': overheadBufferPercent,
      'contingencyPercent': contingencyPercent,
    };
  }
}

class Estimate {
  String estimateId;
  ProjectClientInfo clientInfo;
  PackageTier selectedPackage;
  List<MaterialRate> materials;
  List<PhaseMilestone> phases;
  List<BOQItem> boqItems;
  List<LabourEntry> labour;
  ProfitMarginConfig margin;
  EstimateStatus status;
  DateTime createdAt;
  DateTime? approvedAt;
  String? approvedByUserId;

  // Derived Calculations
  double get materialCost => materials.fold(0.0, (s, m) => s + m.quantityRatioPerSqFt * clientInfo.builtUpAreaSqFt * m.baseRate);
  double get labourCost => labour.fold(0.0, (s, l) => s + l.totalCost);
  double get baseCost => materialCost + labourCost;
  double get overheadAmount => baseCost * margin.overheadBufferPercent / 100;
  double get marginAmount => (baseCost + overheadAmount) * margin.marginPercent / 100;
  double get totalCost => baseCost + overheadAmount + marginAmount;
  double get costPerSqFt => clientInfo.builtUpAreaSqFt == 0.0 ? 0.0 : totalCost / clientInfo.builtUpAreaSqFt;

  Estimate({
    required this.estimateId,
    required this.clientInfo,
    required this.selectedPackage,
    required this.materials,
    required this.phases,
    required this.boqItems,
    required this.labour,
    required this.margin,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedByUserId,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) {
    String pkgStr = (json['selectedPackage'] ?? 'standard').toString().toLowerCase();
    PackageTier pkg = PackageTier.standard;
    if (pkgStr == 'economy') pkg = PackageTier.economy;
    if (pkgStr == 'premium') pkg = PackageTier.premium;

    String statusStr = (json['status'] ?? 'pendingApproval').toString();
    EstimateStatus status = EstimateStatus.pendingApproval;
    if (statusStr.toLowerCase() == 'draft') status = EstimateStatus.draft;
    if (statusStr.toLowerCase() == 'approved') status = EstimateStatus.approved;
    if (statusStr.toLowerCase() == 'rejected') status = EstimateStatus.rejected;
    if (statusStr.toLowerCase() == 'active') status = EstimateStatus.active;
    if (statusStr.toLowerCase() == 'archived') status = EstimateStatus.archived;

    return Estimate(
      estimateId: json['id']?.toString() ?? json['estimateId']?.toString() ?? '',
      clientInfo: ProjectClientInfo.fromJson(json),
      selectedPackage: pkg,
      materials: json['materials'] != null
          ? (json['materials'] as List).map((x) => MaterialRate.fromJson(x)).toList()
          : [],
      phases: json['phases'] != null
          ? (json['phases'] as List).map((x) => PhaseMilestone.fromJson(x)).toList()
          : [],
      boqItems: json['boq'] != null || json['boqItems'] != null
          ? ((json['boq'] ?? json['boqItems']) as List).map((x) => BOQItem.fromJson(x)).toList()
          : [],
      labour: json['labours'] ?? json['labour'] != null
          ? ((json['labours'] ?? json['labour']) as List).map((x) => LabourEntry.fromJson(x)).toList()
          : [],
      margin: ProfitMarginConfig.fromJson(json),
      status: status,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'].toString()) : null,
      approvedByUserId: json['approvedByUserId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': estimateId,
      'projectName': clientInfo.projectName,
      'clientName': clientInfo.clientName,
      'projectType': clientInfo.projectType,
      'clientContact': clientInfo.clientContact,
      'builtUpArea': clientInfo.builtUpAreaSqFt,
      'unit': clientInfo.unit,
      'floorPlanFileUrl': clientInfo.floorPlanFileUrl,
      'aiExtractedAreas': clientInfo.aiExtractedAreas,
      'selectedPackage': selectedPackage.name,
      'status': status.name,
      'materials': materials.map((x) => x.toJson()).toList(),
      'phases': phases.map((x) => x.toJson()).toList(),
      'boq': boqItems.map((x) => x.toJson()).toList(),
      'labours': labour.map((x) => x.toJson()).toList(),
      ...margin.toJson(),
      'totalCost': totalCost,
      'baseCost': baseCost,
      'materialCost': materialCost,
      'labourCost': labourCost,
      'netProjectValue': totalCost,
      'packageRate': costPerSqFt,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedByUserId': approvedByUserId,
    };
  }
}

extension on ProjectClientInfo {
  String get projectName => clientName.isNotEmpty ? '$clientName\'s Project' : 'Horizon Villa ECR';
  String get unit => 'Square Feet';
}

class ActiveProject {
  String projectId;
  String estimateId;
  double estimatedBudget; // frozen snapshot at approval
  double actualSpentMaterials;
  double actualSpentLabour;
  double actualSpentSiteExpenses;

  double get actualTotal => actualSpentMaterials + actualSpentLabour + actualSpentSiteExpenses;
  double get variance => estimatedBudget - actualTotal; // positive = under budget, negative = overrun
  double get variancePercent => estimatedBudget == 0.0 ? 0.0 : (variance / estimatedBudget) * 100.0;

  ActiveProject({
    required this.projectId,
    required this.estimateId,
    required this.estimatedBudget,
    required this.actualSpentMaterials,
    required this.actualSpentLabour,
    required this.actualSpentSiteExpenses,
  });

  factory ActiveProject.fromJson(Map<String, dynamic> json) {
    return ActiveProject(
      projectId: json['projectId']?.toString() ?? json['id']?.toString() ?? '',
      estimateId: json['estimateId']?.toString() ?? '',
      estimatedBudget: double.tryParse(json['estimatedBudget']?.toString() ?? json['totalEstimatedCost']?.toString() ?? '0.0') ?? 0.0,
      actualSpentMaterials: double.tryParse(json['actualSpentMaterials']?.toString() ?? json['actualMaterialCost']?.toString() ?? '0.0') ?? 0.0,
      actualSpentLabour: double.tryParse(json['actualSpentLabour']?.toString() ?? json['actualLabourCost']?.toString() ?? '0.0') ?? 0.0,
      actualSpentSiteExpenses: double.tryParse(json['actualSpentSiteExpenses']?.toString() ?? json['actualExpenses']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'estimateId': estimateId,
      'estimatedBudget': estimatedBudget,
      'actualSpentMaterials': actualSpentMaterials,
      'actualSpentLabour': actualSpentLabour,
      'actualSpentSiteExpenses': actualSpentSiteExpenses,
    };
  }
}

class EstimationEngineSettings {
  double economyRatePerSqFt;
  double standardRatePerSqFt;
  double premiumRatePerSqFt;
  double defaultMarginPercent;
  double defaultOverheadPercent;
  DateTime lastModified;
  String lastModifiedByUserId;

  EstimationEngineSettings({
    required this.economyRatePerSqFt,
    required this.standardRatePerSqFt,
    required this.premiumRatePerSqFt,
    required this.defaultMarginPercent,
    required this.defaultOverheadPercent,
    required this.lastModified,
    required this.lastModifiedByUserId,
  });

  factory EstimationEngineSettings.fromJson(Map<String, dynamic> json) {
    return EstimationEngineSettings(
      economyRatePerSqFt: double.tryParse(json['economyRate']?.toString() ?? '2200.0') ?? 2200.0,
      standardRatePerSqFt: double.tryParse(json['standardRate']?.toString() ?? '2500.0') ?? 2500.0,
      premiumRatePerSqFt: double.tryParse(json['premiumRate']?.toString() ?? '2800.0') ?? 2800.0,
      defaultMarginPercent: double.tryParse(json['profitMarginPercentage']?.toString() ?? '15.0') ?? 15.0,
      defaultOverheadPercent: double.tryParse(json['companyOverheadPercent']?.toString() ?? '5.0') ?? 5.0,
      lastModified: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now(),
      lastModifiedByUserId: json['lastModifiedByUserId']?.toString() ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'economyRate': economyRatePerSqFt,
      'standardRate': standardRatePerSqFt,
      'premiumRate': premiumRatePerSqFt,
      'profitMarginPercentage': defaultMarginPercent,
      'companyOverheadPercent': defaultOverheadPercent,
      'updatedAt': lastModified.toIso8601String(),
      'lastModifiedByUserId': lastModifiedByUserId,
    };
  }
}
