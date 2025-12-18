import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'userProfile': 'User Profile',
      'changeUsername': 'Change Username',
      'changePassword': 'Change Password',
      'plantProfile': 'Plant Profile',
      'activeProfile': 'Active Profile',
      'selectProfile': 'Select Profile',
      'currentSetpoints': 'Current Setpoints:',
      'tempRange': 'Temp Range',
      'vpdTarget': 'VPD Target',
      'co2Limit': 'CO2 Limit',
      'lightMax': 'Light Max',
      'soilMin': 'Soil Min',
      'language': 'Language',
      'appLanguage': 'App Language',
      'english': 'English',
      'chinese': 'Chinese',
      'soilSensorCalibration': 'Soil Sensor Calibration',
      'calibrationDesc':
          'Calibrate the soil moisture sensor by setting the raw ADC values for dry (air) and wet (water) conditions.',
      'dryValue': 'Dry Value (Air)',
      'wetValue': 'Wet Value (Water)',
      'saveCalibration': 'Save Calibration',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'required': 'Required',
      'failed': 'Failed',
      'success': 'Success',
      'oldPassword': 'Old Password',
      'newPassword': 'New Password',
      'newUsername': 'New Username',
      'min6Chars': 'Min 6 chars',
      'passwordChanged': 'Password changed successfully',
      'usernameChanged': 'Username changed successfully',
      // Navigation
      'dashboard': 'Dashboard',
      'shop': 'Shop',
      'news': 'News',
      // Dashboard
      'smartGreenhouse': 'Smart Greenhouse',
      'lastUpdated': 'Last Updated',
      'temp': 'Temp',
      'humidity': 'Humidity',
      'light': 'Light',
      'soil': 'Soil',
      'co2': 'CO2',
      'vpd': 'VPD',
      'historyTrends': 'History Trends',
      // Shop
      'seedShop': 'Seed Shop',
      'myShop': 'My Shop',
      'myOrders': 'My Orders',
      'viewCart': 'View Cart',
      'noProductsFound': 'No products found.',
      'retry': 'Retry',
      'addedToCart': 'Added to cart',
      // Shop Management
      'myShopManagement': 'My Shop Management',
      'postNewSeed': 'Post New Seed',
      'noSeedsPosted': 'You haven\'t posted any seeds yet.',
      'postFirstSeed': 'Post Your First Seed',
      'deleteProduct': 'Delete Product',
      'deleteConfirm': 'Are you sure you want to delete this product?',
      'delete': 'Delete',
      'productDeleted': 'Product deleted',
      'deleteFailed': 'Failed to delete product',
      'seedName': 'Seed Name',
      'description': 'Description',
      'price': 'Price',
      'stockQuantity': 'Stock Quantity',
      'addPhoto': 'Add Photo',
      'post': 'Post',
      'uploadFailed': 'Failed to upload image. Please try again.',
      'postSuccess': 'Seed posted successfully!',
      'postFailed': 'Failed to post seed',
      // Plant Info
      'plantNewsInfo': 'Plant News & Info',
      'noPlantInfo': 'No plant information available.',
      // Chat & Friends
      'chats': 'Chats',
      'pleaseLoginChat': 'Please login to chat',
      'noFriendsFound': 'No friends found. Add friends to chat!',
      'friends': 'Friends',
      'addFriendByUsername': 'Add friend by username',
      'add': 'Add',
      'pendingRequests': 'Pending Requests',
      'friendRequestSent': 'Friend request sent to',
      'failedSendMessage': 'Failed to send message',
    },
    'zh': {
      'settings': '设置',
      'userProfile': '用户资料',
      'changeUsername': '修改用户名',
      'changePassword': '修改密码',
      'plantProfile': '植物配置',
      'activeProfile': '当前配置',
      'selectProfile': '选择配置',
      'currentSetpoints': '当前设定值:',
      'tempRange': '温度范围',
      'vpdTarget': 'VPD 目标',
      'co2Limit': 'CO2 上限',
      'lightMax': '光照上限',
      'soilMin': '土壤湿度下限',
      'language': '语言',
      'appLanguage': '应用语言',
      'english': '英文',
      'chinese': '中文',
      'soilSensorCalibration': '土壤传感器校准',
      'calibrationDesc': '通过设置干燥（空气）和潮湿（水）条件下的原始 ADC 值来校准土壤湿度传感器。',
      'dryValue': '干燥值 (空气)',
      'wetValue': '潮湿值 (水)',
      'saveCalibration': '保存校准',
      'logout': '登出',
      'cancel': '取消',
      'required': '必填',
      'failed': '失败',
      'success': '成功',
      'oldPassword': '旧密码',
      'newPassword': '新密码',
      'newUsername': '新用户名',
      'min6Chars': '至少6个字符',
      'passwordChanged': '密码修改成功',
      'usernameChanged': '用户名修改成功',
      // Navigation
      'dashboard': '仪表盘',
      'shop': '商店',
      'news': '资讯',
      // Dashboard
      'smartGreenhouse': '智能温室',
      'lastUpdated': '最后更新',
      'temp': '温度',
      'humidity': '湿度',
      'light': '光照',
      'soil': '土壤',
      'co2': '二氧化碳',
      'vpd': 'VPD',
      'historyTrends': '历史趋势',
      // Shop
      'seedShop': '种子商店',
      'myShop': '我的商店',
      'myOrders': '我的订单',
      'viewCart': '查看购物车',
      'noProductsFound': '未找到商品。',
      'retry': '重试',
      'addedToCart': '已加入购物车',
      // Shop Management
      'myShopManagement': '店铺管理',
      'postNewSeed': '发布新种子',
      'noSeedsPosted': '您还没有发布任何种子。',
      'postFirstSeed': '发布您的第一个种子',
      'deleteProduct': '删除商品',
      'deleteConfirm': '确定要删除此商品吗？',
      'delete': '删除',
      'productDeleted': '商品已删除',
      'deleteFailed': '删除商品失败',
      'seedName': '种子名称',
      'description': '描述',
      'price': '价格',
      'stockQuantity': '库存数量',
      'addPhoto': '添加照片',
      'post': '发布',
      'uploadFailed': '图片上传失败，请重试。',
      'postSuccess': '种子发布成功！',
      'postFailed': '种子发布失败',
      // Plant Info
      'plantNewsInfo': '植物资讯',
      'noPlantInfo': '暂无植物资讯。',
      // Chat & Friends
      'chats': '聊天',
      'pleaseLoginChat': '请登录后聊天',
      'noFriendsFound': '暂无好友。添加好友开始聊天！',
      'friends': '好友',
      'addFriendByUsername': '通过用户名添加好友',
      'add': '添加',
      'pendingRequests': '待处理请求',
      'friendRequestSent': '好友请求已发送至',
      'failedSendMessage': '发送消息失败',
    },
  };

  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get userProfile =>
      _localizedValues[locale.languageCode]!['userProfile']!;
  String get changeUsername =>
      _localizedValues[locale.languageCode]!['changeUsername']!;
  String get changePassword =>
      _localizedValues[locale.languageCode]!['changePassword']!;
  String get plantProfile =>
      _localizedValues[locale.languageCode]!['plantProfile']!;
  String get activeProfile =>
      _localizedValues[locale.languageCode]!['activeProfile']!;
  String get selectProfile =>
      _localizedValues[locale.languageCode]!['selectProfile']!;
  String get currentSetpoints =>
      _localizedValues[locale.languageCode]!['currentSetpoints']!;
  String get tempRange => _localizedValues[locale.languageCode]!['tempRange']!;
  String get vpdTarget => _localizedValues[locale.languageCode]!['vpdTarget']!;
  String get co2Limit => _localizedValues[locale.languageCode]!['co2Limit']!;
  String get lightMax => _localizedValues[locale.languageCode]!['lightMax']!;
  String get soilMin => _localizedValues[locale.languageCode]!['soilMin']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get appLanguage =>
      _localizedValues[locale.languageCode]!['appLanguage']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get chinese => _localizedValues[locale.languageCode]!['chinese']!;
  String get soilSensorCalibration =>
      _localizedValues[locale.languageCode]!['soilSensorCalibration']!;
  String get calibrationDesc =>
      _localizedValues[locale.languageCode]!['calibrationDesc']!;
  String get dryValue => _localizedValues[locale.languageCode]!['dryValue']!;
  String get wetValue => _localizedValues[locale.languageCode]!['wetValue']!;
  String get saveCalibration =>
      _localizedValues[locale.languageCode]!['saveCalibration']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get required => _localizedValues[locale.languageCode]!['required']!;
  String get failed => _localizedValues[locale.languageCode]!['failed']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get oldPassword =>
      _localizedValues[locale.languageCode]!['oldPassword']!;
  String get newPassword =>
      _localizedValues[locale.languageCode]!['newPassword']!;
  String get newUsername =>
      _localizedValues[locale.languageCode]!['newUsername']!;
  String get min6Chars => _localizedValues[locale.languageCode]!['min6Chars']!;
  String get passwordChanged =>
      _localizedValues[locale.languageCode]!['passwordChanged']!;
  String get usernameChanged =>
      _localizedValues[locale.languageCode]!['usernameChanged']!;

  // Navigation
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get shop => _localizedValues[locale.languageCode]!['shop']!;
  String get news => _localizedValues[locale.languageCode]!['news']!;

  // Dashboard
  String get smartGreenhouse =>
      _localizedValues[locale.languageCode]!['smartGreenhouse']!;
  String get lastUpdated =>
      _localizedValues[locale.languageCode]!['lastUpdated']!;
  String get temp => _localizedValues[locale.languageCode]!['temp']!;
  String get humidity => _localizedValues[locale.languageCode]!['humidity']!;
  String get light => _localizedValues[locale.languageCode]!['light']!;
  String get soil => _localizedValues[locale.languageCode]!['soil']!;
  String get co2 => _localizedValues[locale.languageCode]!['co2']!;
  String get vpd => _localizedValues[locale.languageCode]!['vpd']!;
  String get historyTrends =>
      _localizedValues[locale.languageCode]!['historyTrends']!;

  // Shop
  String get seedShop => _localizedValues[locale.languageCode]!['seedShop']!;
  String get myShop => _localizedValues[locale.languageCode]!['myShop']!;
  String get myOrders => _localizedValues[locale.languageCode]!['myOrders']!;
  String get viewCart => _localizedValues[locale.languageCode]!['viewCart']!;
  String get noProductsFound =>
      _localizedValues[locale.languageCode]!['noProductsFound']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get addedToCart =>
      _localizedValues[locale.languageCode]!['addedToCart']!;

  // Shop Management
  String get myShopManagement =>
      _localizedValues[locale.languageCode]!['myShopManagement']!;
  String get postNewSeed =>
      _localizedValues[locale.languageCode]!['postNewSeed']!;
  String get noSeedsPosted =>
      _localizedValues[locale.languageCode]!['noSeedsPosted']!;
  String get postFirstSeed =>
      _localizedValues[locale.languageCode]!['postFirstSeed']!;
  String get deleteProduct =>
      _localizedValues[locale.languageCode]!['deleteProduct']!;
  String get deleteConfirm =>
      _localizedValues[locale.languageCode]!['deleteConfirm']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get productDeleted =>
      _localizedValues[locale.languageCode]!['productDeleted']!;
  String get deleteFailed =>
      _localizedValues[locale.languageCode]!['deleteFailed']!;
  String get seedName => _localizedValues[locale.languageCode]!['seedName']!;
  String get description =>
      _localizedValues[locale.languageCode]!['description']!;
  String get price => _localizedValues[locale.languageCode]!['price']!;
  String get stockQuantity =>
      _localizedValues[locale.languageCode]!['stockQuantity']!;
  String get addPhoto => _localizedValues[locale.languageCode]!['addPhoto']!;
  String get post => _localizedValues[locale.languageCode]!['post']!;
  String get uploadFailed =>
      _localizedValues[locale.languageCode]!['uploadFailed']!;
  String get postSuccess =>
      _localizedValues[locale.languageCode]!['postSuccess']!;
  String get postFailed =>
      _localizedValues[locale.languageCode]!['postFailed']!;

  // Plant Info
  String get plantNewsInfo =>
      _localizedValues[locale.languageCode]!['plantNewsInfo']!;
  String get noPlantInfo =>
      _localizedValues[locale.languageCode]!['noPlantInfo']!;

  // Chat & Friends
  String get chats => _localizedValues[locale.languageCode]!['chats']!;
  String get pleaseLoginChat =>
      _localizedValues[locale.languageCode]!['pleaseLoginChat']!;
  String get noFriendsFound =>
      _localizedValues[locale.languageCode]!['noFriendsFound']!;
  String get friends => _localizedValues[locale.languageCode]!['friends']!;
  String get addFriendByUsername =>
      _localizedValues[locale.languageCode]!['addFriendByUsername']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get pendingRequests =>
      _localizedValues[locale.languageCode]!['pendingRequests']!;
  String get friendRequestSent =>
      _localizedValues[locale.languageCode]!['friendRequestSent']!;
  String get failedSendMessage =>
      _localizedValues[locale.languageCode]!['failedSendMessage']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
