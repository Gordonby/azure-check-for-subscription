# Gate Success Evaluation

Elaborating on the Azure Function Gate Success Criteria Evaluation a little more.

## Success Criteria used
Taking this gate criteria as the example
```
eq(jsonpath('$.tags.Readiness')[0], 'Ready')
```

## Request Body

```json
{
  "AuthToken": ***,
  "URI": "https://gdoggmsft.visualstudio.com/",
  "ProjectId": "f3456883-1628-4307-bad5-c98c89fddad5",
  "Project": "EntScaleT9",
  "BuildId": "3217"
}
```

## Response Received

```json
 {
  "subName": "gobyers-int",
  "subfound": true,
  "subId": "REDACTED",
  "subState": "Enabled",
  "tags": {
    "Readiness": "Ready",
    "FavouriteColour": "Red"
  }

```

## Criteria Evaluation

```
Parsing expression: <eq(jsonpath('$.tags.Readiness')[0], 'Ready')>
				eq
				(
				..jsonpath
				(
				....'$.tags.Readiness'
				..)
				..[
				....0
				..]
				..,
				..'Ready'
				)
				Evaluating: eq(jsonpath('$.tags.Readiness')[0], 'Ready')
				Evaluating eq:
				..Evaluating indexer:
				....Evaluating jsonpath:
				......Evaluating String:
				......=> '$.tags.Readiness'
				....=> Array
				....Evaluating Number:
				....=> 0
				..=> 'Ready'
				..Evaluating String:
				..=> 'Ready'
				=> True
				Expanded: eq('Ready', 'Ready')
				Result: True
```
