#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USER_NAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE user_name='$USER_NAME'")

if [[ -z $USER_ID ]]
then
  # insert new name and return value, remove INSERT ... from return result
  USER_ID=$($PSQL "INSERT INTO users(user_name) VALUES('$USER_NAME') RETURNING user_id" | grep -v "^INSERT") 
  echo "Welcome, $USER_NAME! It looks like this is your first time here."
else
  # if user exists, read out games_player and best_game from database and display it
  USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id=$USER_ID")
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses." 
fi

NUMBER=$((1 + $RANDOM % 1000))
GUESSES=1
SUCCESS=0

echo "Guess the secret number between 1 and 1000:"

while true
do
  read GUESS
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  if [[ $GUESS == $NUMBER ]]
  then
    echo "You guessed it in $GUESSES tries. The secret number was $NUMBER. Nice job!"
    break
  fi
  if [[ $GUESS -lt $NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
  ((GUESSES++))
done

### update the games_played and best_game stats for the user
# if no user_info was read, it's the users first game
if [[ -z $USER_INFO ]]
then
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$GUESSES WHERE user_id=$USER_ID")
else
  # increase read out games_played stat by 1
  ((GAMES_PLAYED++))
  # check if number of guesses is smaller than current record
  if [[ $GUESSES -lt $BEST_GAME ]]
  then
    BEST_GAME=$GUESSES
  fi
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE user_id=$USER_ID")
fi




