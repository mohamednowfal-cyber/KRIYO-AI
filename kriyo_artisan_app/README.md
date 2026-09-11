# Kriyo Artisan App

Empowering artisans digitally â€” manage crafts, products, orders, earnings, and heritage.

## Getting Started

`ash
flutter pub get
flutter run
`

## Architecture

This project follows **Clean Architecture** with the following layers:
- **Data** â€” Models, data sources, repository implementations
- **Domain** â€” Entities, repository interfaces, use cases
- **Presentation** â€” Screens, widgets, state providers

## Folder Structure

- `lib/app/` â€” App config, constants, routes, theme, localization
- `lib/core/` â€” Error handling, networking, storage, permissions, media, services, utils
- `lib/shared/` â€” Reusable UI components
- `lib/features/` â€” Feature modules (clean architecture per feature)
- `lib/main/` â€” App bootstrap and root widget