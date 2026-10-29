# Farmácia Fácil — App Entregador

## Como rodar

```bash
flutter pub get
flutter run -d chrome
```

O app abre em http://localhost:8080 (ou porta indicada).

## Como criar o primeiro entregador

1. Acesse o [Firebase Console](https://console.firebase.google.com/) → projeto `farmacia-facil-b980c`.
2. **Authentication → Users → Add user**: crie um usuário com e-mail e senha.
3. Copie o **UID** gerado.
4. **Firestore Database → coleção `delivery_persons`** → adicione um documento com **ID = UID** contendo:
   - name, email, phone, isActive (true), createdAt (ISO string)
5. Faça login no app com esse e-mail e senha.

## Funcionalidades

- Login de entregador (verificação na coleção delivery_persons)
- Pedidos disponíveis (status "ready" sem entregador)
- Aceitar pedido (muda para "delivering" e atribui ao entregador)
- Meus pedidos (em rota / concluídos)
- Marcar como entregue
- Histórico de entregas

## Fluxo de status

  ready (pronto) → entregador aceita → delivering (em rota) → entregue (delivered)

## Estrutura de pastas

```
lib/
  main.dart
  firebase_options.dart
  app/        (theme, routes)
  models/     (delivery_person, order)
  providers/  (auth, orders)
  screens/    (auth, orders, history)
  widgets/    (delivery_shell)
```
