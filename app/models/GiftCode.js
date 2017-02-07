module.exports = (orm, cb, models, BaseModel) =>
  class GiftCode extends BaseModel {
    static generateCode = () => Math.random().toString(36).slice(2);

    hasTimestamps = ['createdAt', 'updatedAt'];
    tableName = 'gift_code';
    idAttribute = 'id';

    purchaser = () => this.belongsTo(models.User, 'purchased_by');
    redeemer = () => this.belongsTo(models.User, 'redeemed_by');

    static claim(code, user) {
      return orm.transaction(async tx => {
        const giftCode = await GiftCode
          .where({ code })
          .fetch({ require: true, transacting: tx });

        if (giftCode.isRedeemed()) {
          throw new Error(`GiftCode ${code} is already redeemed`);
        }

        await giftCode.save({ redeemed_by: user.id }, { transacting: tx });
        await user.save({ purchased: true }, { transacting: tx });

        return GiftCode
          .where({ id: giftCode.id })
          .fetch({
            withRelated: ['purchaser', 'redeemer'],
            required: true,
            transacting: tx,
          });
      });
    }

    isRedeemed() {
      return this.get('redeemedBy') != null;
    }
  };
