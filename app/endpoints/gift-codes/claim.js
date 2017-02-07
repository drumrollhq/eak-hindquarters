import joi from 'joi';

export const use = 'auth.logged-in';

export const handler = async ({ user, params: { code }, models: { GiftCode } }) => {
  const giftCode = await GiftCode.claim(code, user);

  return {
    ...giftCode.toJSON(),
    redeemer: giftCode.relations.redeemer.toSafeJson(),
    purchaser: giftCode.relations.purchaser.toSafeJson(),
  };
}
