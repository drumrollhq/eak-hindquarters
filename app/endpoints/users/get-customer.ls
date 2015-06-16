export use = 'users.user-id'
export handler = ({user}) -> user.find-or-create-stripe-customer!
