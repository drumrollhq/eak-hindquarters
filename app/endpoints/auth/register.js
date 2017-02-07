import { empty } from 'prelude-ls';
import { pick } from 'lodash';
import joi from 'joi';
import checkit from 'checkit';
import { filteredImport } from '../../utils';

export const body = joi.object().unknown(true).keys({
  id: joi.number().integer().positive().optional(),
  firstName: joi.string().trim().min(1).optional(),
  lastName: joi.string().trim().min(1).optional(),
  assumeAdult: joi.boolean().required(),
  username: joi.string().min(3).max(18).token().optional(),
  password: joi.string().min(6).optional(),
  passwordConfirm: joi.string().min(6).optional(),
  email: joi.string().email().required(),
  gender: joi.string().optional(),
  subscribedNewsletter: joi.boolean().default(false),
});

export const validationOption = { stripUnknown: true };

export const handler = ({ models: { User, AuthedAction }, body, user, config, session, errors }) => {
  const data = pick(body, ['id', 'firstName', 'lastName', 'assumeAdult', 'username', 'password',
    'passwordConfirm', 'email', 'gender', 'subscribedNewsletter']);

  const creatingUser = data.id != null && data.id === user.id
    ? user.fetch({ withRelated: ['oauths'] }).then(u => u.set(data))
    : Promise.resolve(User.forge(data));

  return creatingUser
    .tap(newUser =>
      newUser.validate({
        role: empty(newUser.related('oauths') ? ['full', 'password'] : ['full']),
      }))
    .then(newUser =>
      newUser
        .set('status', newUser.get('verifiedEmail') ? 'active' : 'pending')
        .save())
    .tap(newUser => {
      if (newUser.get('verifiedEmail')) {
        // Send welcome email
        return newUser.sendMail('signup-welcome');
      } else {
        // Send verify + welcome email
        return AuthedAction
          .create(newUser, 'verify-email')
          .then(key => {
            const template = newUser.adult() ? 'signup-confirm' : 'signup-confirm-parent';
            return newUser.sendMail(template, {
              confirm: `${config.APP_ROOT}/v1/action/verify-email/${key}`,
            });
          });
      }
    })
    .then(newUser => {
      session.passport = { user: newUser.id };
      return newUser.toSafeJson();
    })
    .catch(checkit.Error, err => errors.checkitError(err));
};
