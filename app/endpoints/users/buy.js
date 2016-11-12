import joi from 'joi';
import stripe from '../../../lib/stripe';

const amounts = {
  parent: 400,
};

// how did i think this was a good API???
export const user = 'users.user-id';

export const body = joi.object().keys({
  type: joi.allow('parent').required(),
  token: joi.string().regex(/^tok_/).required(),
  ip: joi.string().ip().required(),
  cardCountry: joi.string().length(2),
  userCountry: joi.string().length(2).required(),
});

export const handler = ({ body, user }) => {
  const { type, token, ip, cardCountry, userCountry } = body;
  return user.setCountry({ ip, cardCountry, userCountry })
    .then(() => user.findOrCreateStripeCustomer(token))
    .then(customer => stripe.charges.create({
      amount: amounts[type],
      currency: 'GBP',
      description: 'Erase All Kittens game',
      statement_descriptor: 'Erase All Kittens game',
      metadata: { buyType: type },
      receipt_email: user.email,
      customer: customer.id,
    }))
    .then(() => user.save({ purchased: true }, { patch: true }))
    .then(saved => saved.toSafeJson());
};
