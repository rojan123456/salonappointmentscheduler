#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -q -t --no-align"

print_services() {
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo
print_services

while true; do
  read SERVICE_ID_SELECTED
  SERVICE_NAME=""
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  echo
  echo "I could not find that service. What would you like today?"
  print_services
done

echo
echo "What's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_INFO=$($PSQL -F '|' -v phone="$CUSTOMER_PHONE" <<'SQL'
SELECT customer_id, name FROM customers WHERE phone = :'phone';
SQL
)
IFS='|' read -r CUSTOMER_ID CUSTOMER_NAME <<< "$CUSTOMER_INFO"

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_ID=$($PSQL -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" <<'SQL'
INSERT INTO customers (phone, name) VALUES (:'phone', :'name') RETURNING customer_id;
SQL
)
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

$PSQL -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" <<'SQL' > /dev/null
INSERT INTO appointments (customer_id, service_id, time) VALUES (:customer_id, :service_id, :'service_time');
SQL

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."