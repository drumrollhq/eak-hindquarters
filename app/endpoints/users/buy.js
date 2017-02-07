import joi from 'joi';
import stripe from '../../../lib/stripe';
import { prices } from '../../constants';

// how did i think this was a good API???
export const use = { 'users.user-id': { fetch: true } };

export const body = joi.object().keys({
  type: joi.allow('parent').required(),
  token: joi.string().regex(/^tok_/).required(),
  ip: joi.string().ip().required(),
  cardCountry: joi.string().length(2),
  userCountry: joi.string().length(2).required(),
});

export const handler = ({ body, user }) => {
  const { type, token, ip, cardCountry, userCountry } = body;
  return user
    .charge({
      amount: prices[type],
      description: 'Erase All Kittens game',
      metadata: { buyType: type },
      token,
      ip,
      cardCountry,
      userCountry,
    })
    .then(() => user.save({ purchased: true }, { patch: true }))
    .then(saved => saved.toSafeJson());
};
