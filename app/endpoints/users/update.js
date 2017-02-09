import joi from 'joi';

export const user = 'users.user-id';

export const body = joi.object().keys({
    status: joi.string().trim().min(1).optional(),
    purchased: joi.boolean().optional()
});

export const validationOption = { stripUnknown: true };

export const handler = ({ body, user }) => {
  const { status, purchased } = body;
  user.save({ purchased: purchased, status: status }, { patch: true });
  return user;
};
