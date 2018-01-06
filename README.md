# listmanagerbot
Telegram bot to manage lists, no need to set up, just start adding items and the list will be created automatically.

```
/add Mr. Robot to Series
```

###  Commands:

- `/list list_name`: List items from a list
- `/lists`: List all your lists
- `/add item to list_name`: Add a new item to a list (send items separated by commas to add multiple records)
- `/confirm item in list_name`: Confirm an item in a list (send items separated by commas to confirm multiple records)
- `/cancel item in list_name`: Cancel an item in a list (send items separated by commas to cancel multiple records)
- `/remove item from list_name`: Remove an item from a list (send items separated by commas to remove multiple records)
- `/delete list_name`: Delete a list
- `/start`: Start a conversation with the bot
- `/help`: Show list of commands

Tip: you have a default list, you can add/confirm/cancel/remove items to it if don't provide a list name, examples:
```
/add item
/list
/confirm item
/cancel item
/remove item
```

## Built With

* [telegram-webhooks](https://github.com/ChaosSteffen/telegram-webhooks) - A DSL-like implementation of the Telegram Bot API.

## Contributing

Fork and PR :)

## Authors

* **JorgeLu1s** - *Initial work*
