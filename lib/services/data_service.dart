import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/deal.dart';
import '../models/interaction.dart';

class DataService {
  static const _contactsBox = 'contacts_v2';
  static const _dealsBox = 'deals_v2';
  static const _interactionsBox = 'interactions_v2';
  static const _relationsBox = 'relations_v2';
  static const _uuid = Uuid();

  late Box _contacts;
  late Box _deals;
  late Box _interactions;
  late Box _relations;

  Future<void> init() async {
    await Hive.initFlutter();
    _contacts = await Hive.openBox(_contactsBox);
    _deals = await Hive.openBox(_dealsBox);
    _interactions = await Hive.openBox(_interactionsBox);
    _relations = await Hive.openBox(_relationsBox);

    if (_contacts.isEmpty) {
      await _loadSampleData();
    }
  }

  // Contact CRUD
  List<Contact> getAllContacts() {
    return _contacts.values
        .map((e) => Contact.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.lastContactedAt.compareTo(a.lastContactedAt));
  }

  Contact? getContact(String id) {
    final data = _contacts.get(id);
    if (data == null) return null;
    return Contact.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveContact(Contact contact) async {
    await _contacts.put(contact.id, contact.toJson());
  }

  Future<void> deleteContact(String id) async {
    await _contacts.delete(id);
  }

  // Relation CRUD
  List<ContactRelation> getAllRelations() {
    return _relations.values
        .map((e) => ContactRelation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<ContactRelation> getRelationsForContact(String contactId) {
    return getAllRelations()
        .where((r) => r.fromContactId == contactId || r.toContactId == contactId)
        .toList();
  }

  Future<void> saveRelation(ContactRelation relation) async {
    await _relations.put(relation.id, relation.toJson());
  }

  Future<void> deleteRelation(String id) async {
    await _relations.delete(id);
  }

  // Deal CRUD
  List<Deal> getAllDeals() {
    return _deals.values
        .map((e) => Deal.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Deal> getDealsByStage(DealStage stage) {
    return getAllDeals().where((d) => d.stage == stage).toList();
  }

  List<Deal> getDealsByContact(String contactId) {
    return getAllDeals().where((d) => d.contactId == contactId).toList();
  }

  Future<void> saveDeal(Deal deal) async {
    await _deals.put(deal.id, deal.toJson());
  }

  Future<void> deleteDeal(String id) async {
    await _deals.delete(id);
  }

  // Interaction CRUD
  List<Interaction> getAllInteractions() {
    return _interactions.values
        .map((e) => Interaction.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Interaction> getInteractionsByContact(String contactId) {
    return getAllInteractions()
        .where((i) => i.contactId == contactId)
        .toList();
  }

  Future<void> saveInteraction(Interaction interaction) async {
    await _interactions.put(interaction.id, interaction.toJson());
  }

  Future<void> deleteInteraction(String id) async {
    await _interactions.delete(id);
  }

  // Stats
  Map<String, dynamic> getStats() {
    final contacts = getAllContacts();
    final deals = getAllDeals();
    final activeDeals =
        deals.where((d) => d.stage != DealStage.closed && d.stage != DealStage.lost).toList();
    final closedDeals = deals.where((d) => d.stage == DealStage.closed).toList();

    double pipelineValue = 0;
    for (final d in activeDeals) {
      pipelineValue += d.amount;
    }
    double closedValue = 0;
    for (final d in closedDeals) {
      closedValue += d.amount;
    }

    final industryCount = <Industry, int>{};
    for (final c in contacts) {
      industryCount[c.industry] = (industryCount[c.industry] ?? 0) + 1;
    }

    final stageCount = <DealStage, int>{};
    for (final d in deals) {
      stageCount[d.stage] = (stageCount[d.stage] ?? 0) + 1;
    }

    return {
      'totalContacts': contacts.length,
      'activeDeals': activeDeals.length,
      'pipelineValue': pipelineValue,
      'closedValue': closedValue,
      'closedDeals': closedDeals.length,
      'winRate': deals.isNotEmpty
          ? (closedDeals.length / deals.length * 100)
          : 0.0,
      'industryCount': industryCount,
      'stageCount': stageCount,
      'hotContacts': contacts
          .where((c) => c.strength == RelationshipStrength.hot)
          .length,
    };
  }

  String generateId() => _uuid.v4();

  Future<void> _loadSampleData() async {
    final ids = List.generate(20, (_) => _uuid.v4());

    final sampleContacts = [
      Contact(id: ids[0], name: '石井正太', nameReading: 'イシイ マサタ', company: "Y's Hair", position: '代表', phone: '090-8933-2497', address: '石川県加賀市', industry: Industry.other, strength: RelationshipStrength.warm, myRelation: MyRelationType.friend, notes: '美容院经营，当地人脉广'),
      Contact(id: ids[1], name: '田中诚一', nameReading: 'タナカ セイイチ', company: '三井住友银行', position: '支行长', phone: '03-5432-1000', email: 'tanaka.s@smbc.co.jp', address: '东京都千代田区', industry: Industry.finance, strength: RelationshipStrength.hot, myRelation: MyRelationType.partner, notes: '主银行负责人，融资通道核心'),
      Contact(id: ids[2], name: '佐藤美咲', nameReading: 'サトウ ミサキ', company: '野村证券', position: 'MD', phone: '03-6741-1234', email: 'misaki.sato@nomura.com', address: '东京都中央区', industry: Industry.finance, strength: RelationshipStrength.hot, myRelation: MyRelationType.advisor, notes: 'IPO/M&A通道，深度信任'),
      Contact(id: ids[3], name: '山本健太', nameReading: 'ヤマモト ケンタ', company: '东急不动产', position: '部长', phone: '03-3456-7890', email: 'k.yamamoto@tokyu-land.co.jp', address: '东京都涩谷区', industry: Industry.realEstate, strength: RelationshipStrength.warm, myRelation: MyRelationType.client, notes: '海外地产投资意向强'),
      Contact(id: ids[4], name: '铃木大辅', nameReading: 'スズキ ダイスケ', company: '大和房屋工业', position: '董事', phone: '06-6342-1111', email: 'd.suzuki@daiwahouse.co.jp', address: '大阪市北区', industry: Industry.construction, strength: RelationshipStrength.warm, myRelation: MyRelationType.client, notes: '大型建设项目负责'),
      Contact(id: ids[5], name: '高桥直子', nameReading: 'タカハシ ナオコ', company: '外泌体Bio', position: '研发部长', phone: '03-5555-0123', email: 'n.takahashi@exosome-bio.jp', address: '东京都港区', industry: Industry.healthcare, strength: RelationshipStrength.hot, myRelation: MyRelationType.partner, notes: '外泌体研究核心，共同开发中'),
      Contact(id: ids[6], name: '中村浩二', nameReading: 'ナカムラ コウジ', company: '森・滨田松本律所', position: '合伙律师', phone: '03-6212-8330', email: 'k.nakamura@mhm-global.com', address: '东京都千代田区', industry: Industry.legal, strength: RelationshipStrength.warm, myRelation: MyRelationType.advisor, notes: '跨境M&A法务专家'),
      Contact(id: ids[7], name: '渡边一郎', nameReading: 'ワタナベ イチロウ', company: '双日株式会社', position: '海外事业本部长', phone: '03-6871-5000', email: 'i.watanabe@sojitz.com', address: '东京都千代田区', industry: Industry.trading, strength: RelationshipStrength.warm, myRelation: MyRelationType.partner, notes: '中国·东南亚贸易通道'),
      Contact(id: ids[8], name: '伊藤惠美', nameReading: 'イトウ エミ', company: '德勤', position: '高级顾问', phone: '03-6213-1000', email: 'e.ito@deloitte.com', address: '东京都千代田区', industry: Industry.consulting, strength: RelationshipStrength.cool, myRelation: MyRelationType.advisor, notes: '事业重组咨询，PE案件'),
      Contact(id: ids[9], name: '松本隆', nameReading: 'マツモト タカシ', company: '松本料亭', position: '店主', phone: '075-221-5566', email: 'info@matsumoto-ryotei.jp', address: '京都市东山区', industry: Industry.foodBeverage, strength: RelationshipStrength.warm, myRelation: MyRelationType.friend, notes: '高端接待首选，VIP包间'),
      Contact(id: ids[10], name: '木村太郎', nameReading: 'キムラ タロウ', company: 'SBI控股', position: '基金经理', phone: '03-6229-0100', email: 't.kimura@sbi.co.jp', address: '东京都港区', industry: Industry.finance, strength: RelationshipStrength.hot, myRelation: MyRelationType.investor, notes: 'VC投资决策人，对外泌体有兴趣'),
      Contact(id: ids[11], name: '吉田美穗', nameReading: 'ヨシダ ミホ', company: 'LINE', position: '产品经理', phone: '03-4316-2500', email: 'm.yoshida@line.me', address: '东京都新宿区', industry: Industry.technology, strength: RelationshipStrength.cool, myRelation: MyRelationType.other, notes: '技术合作候选'),
      Contact(id: ids[12], name: '小林正人', nameReading: 'コバヤシ マサト', company: 'CBRE日本', position: '高级总监', phone: '03-5288-9288', email: 'm.kobayashi@cbre.co.jp', address: '东京都千代田区', industry: Industry.realEstate, strength: RelationshipStrength.warm, myRelation: MyRelationType.supplier, notes: '海外投资者物件推荐，收益分析'),
      Contact(id: ids[13], name: '加藤裕子', nameReading: 'カトウ ユウコ', company: '武田药品', position: '事业开发部长', phone: '03-3278-2111', email: 'y.kato@takeda.com', address: '东京都中央区', industry: Industry.healthcare, strength: RelationshipStrength.warm, myRelation: MyRelationType.client, notes: '外泌体DDS技术License谈判中'),
      Contact(id: ids[14], name: '山田修', nameReading: 'ヤマダ オサム', company: 'PwC咨询', position: '总监', phone: '03-6212-6800', email: 'o.yamada@pwc.com', address: '东京都千代田区', industry: Industry.consulting, strength: RelationshipStrength.cool, myRelation: MyRelationType.advisor, notes: 'DD案件，估值分析'),
      Contact(id: ids[15], name: '清水龙太', nameReading: 'シミズ リュウタ', company: '清水建设', position: '营业部长', phone: '03-3561-1111', email: 'r.shimizu@shimz.co.jp', address: '东京都中央区', industry: Industry.construction, strength: RelationshipStrength.cool, myRelation: MyRelationType.supplier, notes: '大型总承包'),
      Contact(id: ids[16], name: '王伟明', nameReading: 'オウ イメイ', company: '华润集团', position: '日本代表', phone: '03-5500-8800', email: 'weiming.wang@crc.com.cn', address: '东京都港区', industry: Industry.trading, strength: RelationshipStrength.hot, myRelation: MyRelationType.partner, notes: '中国系集团，日中投资核心窗口'),
      Contact(id: ids[17], name: '林美玲', nameReading: 'リン メイリン', company: '瑞信', position: 'VP', phone: '03-4550-9000', email: 'meiling.lin@credit-suisse.com', address: '东京都港区', industry: Industry.finance, strength: RelationshipStrength.warm, myRelation: MyRelationType.advisor, notes: '财富管理，高净值客户转介'),
      Contact(id: ids[18], name: '冈田浩一', nameReading: 'オカダ コウイチ', company: 'JETRO', position: '海外支援课长', phone: '03-3582-5511', email: 'k.okada@jetro.go.jp', address: '东京都港区', industry: Industry.consulting, strength: RelationshipStrength.warm, myRelation: MyRelationType.other, notes: '海外进出支援，补贴信息'),
      Contact(id: ids[19], name: '藤田康介', nameReading: 'フジタ コウスケ', company: '三菱UFJ摩根', position: 'ED', phone: '03-6213-8500', email: 'k.fujita@mufg.jp', address: '东京都千代田区', industry: Industry.finance, strength: RelationshipStrength.hot, myRelation: MyRelationType.partner, notes: '跨境M&A，IPO主承销'),
    ];

    for (final contact in sampleContacts) {
      await _contacts.put(contact.id, contact.toJson());
    }

    // 联系人之间的关系网络
    final sampleRelations = [
      ContactRelation(id: _uuid.v4(), fromContactId: ids[1], toContactId: ids[19], fromName: '田中诚一', toName: '藤田康介', relationType: '同行', description: '银行业同行，经常联合做syndicate loan'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[2], toContactId: ids[10], fromName: '佐藤美咲', toName: '木村太郎', relationType: '同行', description: '证券/VC圈，IPO项目对接'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[5], toContactId: ids[13], fromName: '高桥直子', toName: '加藤裕子', relationType: '业务合作', description: '外泌体研发与武田药品License合作'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[6], toContactId: ids[14], fromName: '中村浩二', toName: '山田修', relationType: '项目协作', description: 'M&A案件法务+财务DD联合'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[7], toContactId: ids[16], fromName: '渡边一郎', toName: '王伟明', relationType: '贸易伙伴', description: '中日贸易通道，双日与华润合作'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[3], toContactId: ids[12], fromName: '山本健太', toName: '小林正人', relationType: '同行', description: '不动产业界，物件推荐互通'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[4], toContactId: ids[15], fromName: '铃木大辅', toName: '清水龙太', relationType: '甲乙方', description: '大和发包，清水总承包'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[10], toContactId: ids[19], fromName: '木村太郎', toName: '藤田康介', relationType: '投行-VC', description: 'SBI投资的企业由MUFG做IPO'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[16], toContactId: ids[13], fromName: '王伟明', toName: '加藤裕子', relationType: '客户', description: '华润对武田医药品采购'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[17], toContactId: ids[2], fromName: '林美玲', toName: '佐藤美咲', relationType: '同行', description: '瑞信与野村，高净值客户交叉'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[1], toContactId: ids[3], fromName: '田中诚一', toName: '山本健太', relationType: '银行-客户', description: '三井住友为东急提供项目融资'),
      ContactRelation(id: _uuid.v4(), fromContactId: ids[8], toContactId: ids[14], fromName: '伊藤惠美', toName: '山田修', relationType: '同行', description: '四大咨询，DD案件竞合'),
    ];

    for (final relation in sampleRelations) {
      await _relations.put(relation.id, relation.toJson());
    }

    // Sample deals
    final sampleDeals = [
      Deal(id: _uuid.v4(), title: '外泌体DDS技术License', description: '武田药品外泌体药物递送技术授权', contactId: ids[13], contactName: '加藤裕子', stage: DealStage.negotiation, amount: 500000000, probability: 60, notes: '技术评估完成，条件谈判中'),
      Deal(id: _uuid.v4(), title: 'SBI投资基金出资', description: '外泌体事业VC投资', contactId: ids[10], contactName: '木村太郎', stage: DealStage.proposal, amount: 300000000, probability: 40, notes: 'Pitch完成，DD阶段'),
      Deal(id: _uuid.v4(), title: '华润集团日中合资', description: '中国市场医药保健品流通JV', contactId: ids[16], contactName: '王伟明', stage: DealStage.contacted, amount: 200000000, probability: 25, notes: '首次会议已完成'),
      Deal(id: _uuid.v4(), title: '东急不动产海外投资', description: '海外房地产投资基金组成', contactId: ids[3], contactName: '山本健太', stage: DealStage.lead, amount: 1000000000, probability: 10, notes: '初步接触阶段'),
      Deal(id: _uuid.v4(), title: 'MUFG IPO顾问', description: '外泌体事业公司上市准备', contactId: ids[19], contactName: '藤田康介', stage: DealStage.contacted, amount: 150000000, probability: 20, notes: '上市时间表协商中'),
      Deal(id: _uuid.v4(), title: '外泌体共同研发', description: '与高桥博士的外泌体新应用开发', contactId: ids[5], contactName: '高桥直子', stage: DealStage.negotiation, amount: 80000000, probability: 70, notes: '研究计划已合意，预算待定'),
      Deal(id: _uuid.v4(), title: '跨境M&A案件', description: '中国医药企业日本进出支援', contactId: ids[6], contactName: '中村浩二', stage: DealStage.proposal, amount: 250000000, probability: 35, notes: '法务DD进行中'),
      Deal(id: _uuid.v4(), title: 'HNWI资产运用', description: '瑞信经由的财富管理', contactId: ids[17], contactName: '林美玲', stage: DealStage.closed, amount: 120000000, probability: 100, notes: '已成约，AUM扩大中'),
    ];

    for (final deal in sampleDeals) {
      await _deals.put(deal.id, deal.toJson());
    }

    // Sample interactions
    final sampleInteractions = [
      Interaction(id: _uuid.v4(), contactId: ids[1], contactName: '田中诚一', type: InteractionType.meeting, title: '融资额度扩大洽谈', notes: '新事业计划提交，积极回应', date: DateTime.now().subtract(const Duration(days: 2))),
      Interaction(id: _uuid.v4(), contactId: ids[2], contactName: '佐藤美咲', type: InteractionType.dinner, title: '六本木饭局', notes: 'M&A案件3件推荐，下月跟进', date: DateTime.now().subtract(const Duration(days: 5))),
      Interaction(id: _uuid.v4(), contactId: ids[5], contactName: '高桥直子', type: InteractionType.meeting, title: '外泌体共研会议', notes: '技术转让方案合意，NDA签约完', date: DateTime.now().subtract(const Duration(days: 7))),
      Interaction(id: _uuid.v4(), contactId: ids[10], contactName: '木村太郎', type: InteractionType.call, title: '投资检讨进度确认', notes: 'IC资料追加提交要求', date: DateTime.now().subtract(const Duration(days: 3))),
      Interaction(id: _uuid.v4(), contactId: ids[16], contactName: '王伟明', type: InteractionType.meeting, title: '华润集团日本办公室访问', notes: 'JV构想概要说明，反应积极', date: DateTime.now().subtract(const Duration(days: 10))),
      Interaction(id: _uuid.v4(), contactId: ids[19], contactName: '藤田康介', type: InteractionType.email, title: 'IPO时间表确认', notes: '2026Q3上市目标，主承销选定中', date: DateTime.now().subtract(const Duration(days: 1))),
      Interaction(id: _uuid.v4(), contactId: ids[13], contactName: '加藤裕子', type: InteractionType.meeting, title: '武田药品技术评审', notes: 'Phase2数据共享，License条件提示', date: DateTime.now().subtract(const Duration(days: 14))),
      Interaction(id: _uuid.v4(), contactId: ids[9], contactName: '松本隆', type: InteractionType.dinner, title: '松本料亭接待王氏', notes: '华润集团高管接待，关系良好', date: DateTime.now().subtract(const Duration(days: 12))),
    ];

    for (final interaction in sampleInteractions) {
      await _interactions.put(interaction.id, interaction.toJson());
    }
  }
}
