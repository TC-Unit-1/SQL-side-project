import random

turn = int(input("Number of turns: "))

for i in range(turn):
    cards = [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
             5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8,
             9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10,
             10, 10, 10, 10, 10]
    house_hand = []
    player_hand = []

    while sum(player_hand) < 21:
        hit_1 = random.choice(cards)
        player_hand.append(hit_1)
        cards.remove(hit_1)

    while sum(house_hand) < 17:
        hit = random.choice(cards)
        house_hand.append(hit)
        cards.remove(hit)

    if sum(house_hand) > 21 and sum(player_hand) <= 21:
        print(house_hand, ";" ,player_hand, ";Player win")
    elif sum(house_hand) < sum(player_hand) and sum(player_hand) <= 21:
        print(house_hand, ";" ,player_hand, ";Player win")
    elif sum(house_hand) > sum(player_hand) and sum(house_hand) <= 21:
        print(house_hand, ";" ,player_hand, ";House win")
    elif sum(house_hand) == sum(player_hand):
        print(house_hand, ";" ,player_hand, ";Draw")
    elif sum(player_hand) > 21:
        print(house_hand, ";" ,player_hand, ";House win")
