import joi from 'joi';
import { times } from 'lodash';
import stripe from '../../../lib/stripe';
import { prices } from '../../constants';

export const use = 'auth.logged-in';

export const body = joi.object().keys({
  type: joi.allow('parent').required(),
  token: joi.string().regex(/^tok_/).required(),
  ip: joi.string().ip().required(),
  cardCountry: joi.string().length(2),
  userCountry: joi.string().length(2).required(),
  quantity: joi.number().integer().min(1).max(50).required(),
});

export const handler = async ({ body, user, models: { GiftCode, db } }) => {
  await user.fetch();

  const { type, token, ip, cardCountry, userCountry, quantity } = body;
  const amount = quantity * prices[type];

  await user.charge({
    amount: quantity * prices[type],
    description: `E.A.K. gift × ${quantity}`,
    metadata: { gift: true, buyType: type, quantity },
    token,
    ip,
    cardCountry,
    userCountry
  });

  const giftCodes = times(quantity, () => ({
    code: GiftCode.generateCode(),
    purchased_by: user.id,
    created_at: new Date(),
    updated_at: new Date(),
  }));

  const rows = await db
    .insert(giftCodes)
    .into('gift_code')
    .returning('*');

  return rows.map(row => GiftCode.forge(GiftCode.prototype.parse(row)));
};
