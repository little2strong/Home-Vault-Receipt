import 'package:flutter/material.dart';

/// Only Physical items get a room and appear in the home inventory.
enum ItemType {
  physical('Physical'),
  digital('Digital'),
  service('Service'),
  consumable('Consumable');

  const ItemType(this.label);

  final String label;

  static ItemType fromName(String? name) =>
      values.asNameMap()[name] ?? ItemType.physical;
}

enum Purpose {
  home('Home'),
  car('Car'),
  work('Work'),
  gift('Gift'),
  other('Other');

  const Purpose(this.label);

  final String label;

  static Purpose fromName(String? name) =>
      values.asNameMap()[name] ?? Purpose.home;
}

/// Non-owned items leave the inventory but keep their record.
enum ItemStatus {
  owned('Owned'),
  returned('Returned'),
  sold('Sold'),
  broken('Broken'),
  givenAway('Given away');

  const ItemStatus(this.label);

  final String label;

  static ItemStatus fromName(String? name) =>
      values.asNameMap()[name] ?? ItemStatus.owned;
}

enum ReceiptSource {
  camera('Camera scan'),
  photo('Photo'),
  pdf('PDF'),
  manual('Typed in');

  const ReceiptSource(this.label);

  final String label;

  static ReceiptSource fromName(String? name) =>
      values.asNameMap()[name] ?? ReceiptSource.manual;
}

enum PhotoSource {
  camera('In-app camera'),
  gallery('From gallery');

  const PhotoSource(this.label);

  final String label;

  static PhotoSource fromName(String? name) =>
      values.asNameMap()[name] ?? PhotoSource.gallery;
}

/// A word plus colour, never colour alone.
enum WarrantyStatus {
  active('Active'),
  expiring('Expiring'),
  expired('Expired');

  const WarrantyStatus(this.label);

  final String label;
}

enum ExportKind {
  inventory(
    'Home inventory',
    'Items in your home, room by room, with photos. For insurers.',
  ),
  products(
    'Itemised product list',
    "Everything you've bought, filtered by date or purpose.",
  ),
  archive(
    'Everything',
    'All data plus original receipts and photos, in one ZIP.',
  );

  const ExportKind(this.label, this.description);

  final String label;
  final String description;

  static ExportKind fromName(String? name) =>
      values.asNameMap()[name] ?? ExportKind.inventory;
}

enum ExportFormat {
  pdf('PDF'),
  csv('CSV'),
  both('Both'),
  zip('ZIP');

  const ExportFormat(this.label);

  final String label;

  static ExportFormat fromName(String? name) =>
      values.asNameMap()[name] ?? ExportFormat.pdf;
}

enum ExportStatus {
  building('Building…'),
  ready('Ready'),
  failed('Failed'),
  expired('Expired');

  const ExportStatus(this.label);

  final String label;

  static ExportStatus fromName(String? name) =>
      values.asNameMap()[name] ?? ExportStatus.building;
}

/// Category drives the default Type, so most items need no tagging.
enum Category {
  groceries('Groceries', ItemType.consumable, Icons.receipt_long_outlined),
  electronics('Electronics', ItemType.physical, Icons.tv_outlined),
  appliances('Appliances', ItemType.physical, Icons.kitchen_outlined),
  furniture('Furniture', ItemType.physical, Icons.chair_outlined),
  homeDiy('Home & DIY', ItemType.physical, Icons.handyman_outlined),
  lighting('Lighting', ItemType.physical, Icons.light_outlined),
  clothing('Clothing', ItemType.physical, Icons.checkroom_outlined),
  accessories('Accessories', ItemType.physical, Icons.cable_outlined),
  jewellery('Jewellery & watches', ItemType.physical, Icons.watch_outlined),
  car('Car', ItemType.consumable, Icons.directions_car_outlined),
  health('Health & beauty', ItemType.consumable, Icons.spa_outlined),
  software('Software & subscriptions', ItemType.digital, Icons.apps_outlined),
  services('Services', ItemType.service, Icons.build_outlined),
  other('Other', ItemType.physical, Icons.inventory_2_outlined);

  const Category(this.label, this.defaultType, this.icon);

  final String label;
  final ItemType defaultType;
  final IconData icon;

  static Category fromName(String? name) =>
      values.asNameMap()[name] ?? Category.other;
}

/// Room types offered in Home setup, in the design's order.
enum RoomType {
  livingRoom('Living room', 1, Icons.weekend_outlined),
  kitchen('Kitchen', 1, Icons.kitchen_outlined),
  bedroom('Bedroom', 2, Icons.bed_outlined),
  bathroom('Bathroom', 1, Icons.bathtub_outlined),
  diningRoom('Dining room', 1, Icons.table_restaurant_outlined),
  hallway('Hallway', 1, Icons.door_front_door_outlined),
  office('Office', 0, Icons.desk_outlined),
  garage('Garage', 0, Icons.garage_outlined),
  loft('Loft', 0, Icons.roofing_outlined),
  garden('Garden or shed', 1, Icons.yard_outlined),
  custom('Room', 0, Icons.meeting_room_outlined);

  const RoomType(this.label, this.defaultCount, this.icon);

  final String label;
  final int defaultCount;
  final IconData icon;

  static RoomType fromName(String? name) =>
      values.asNameMap()[name] ?? RoomType.custom;
}
