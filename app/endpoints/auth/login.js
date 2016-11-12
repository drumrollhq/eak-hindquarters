import joi from 'joi';

export const body = joi.object().keys({
  username: joi.string().trim().required(),
  password: joi.string().required(),
});

export const handler = ({ errors, body, session, models: { User } }) =>
  User
    .find(body.username)
    .fetch()
    .tap(user => {
      if (user == null) {
        return errors.notFound(`Oh no! We don't seem to have a ${body.userame}. Try signing up!`);
      }

      return user.checkPassword(body.password);
    })
    .then(user => {
      session.passport = { user: user.id };
      return {
        loggedIn: true,
        user: user.toSafeJson(),
      };
    });
