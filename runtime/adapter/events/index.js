function parseBody(req) {
  if (!req || req.body === undefined || req.body === null) {
    return {};
  }

  if (typeof req.body === "string") {
    try {
      return JSON.parse(req.body);
    } catch {
      return null;
    }
  }

  return req.body;
}

function buildErrors(body) {
  const errors = [];

  if (!body || typeof body !== "object") {
    errors.push("request body must be a valid JSON object");
    return errors;
  }

  if (!body.contract || typeof body.contract !== "object") {
    errors.push("contract is required and must be an object");
  } else {
    if (typeof body.contract.version !== "string" || body.contract.version.trim() === "") {
      errors.push("contract.version is required and must be a non-empty string");
    }
    if (typeof body.contract.type !== "string" || body.contract.type.trim() === "") {
      errors.push("contract.type is required and must be a non-empty string");
    }
    if (typeof body.contract.source !== "string" || body.contract.source.trim() === "") {
      errors.push("contract.source is required and must be a non-empty string");
    }
  }

  if (!("payload" in body)) {
    errors.push("payload is required");
  }

  if ("metadata" in body && (typeof body.metadata !== "object" || body.metadata === null || Array.isArray(body.metadata))) {
    errors.push("metadata must be an object when provided");
  }

  return errors;
}

module.exports = async function (context, req) {
  const body = parseBody(req);
  const errors = buildErrors(body);

  if (body === null || errors.length > 0) {
    context.res = {
      status: 400,
      body: {
        accepted: false,
        errors: body === null ? ["request body is not valid JSON"] : errors
      }
    };
    return;
  }

  const eventId = typeof body.eventId === "string" && body.eventId.trim() !== ""
    ? body.eventId
    : context.invocationId;

  const envelope = {
    eventId,
    enqueuedAt: new Date().toISOString(),
    contract: {
      version: body.contract.version,
      type: body.contract.type,
      source: body.contract.source
    },
    payload: body.payload,
    metadata: body.metadata || {},
    trace: {
      requestId: context.invocationId
    }
  };

  context.bindings.outputEventHub = envelope;
  context.log(`adapter enqueued event ${eventId} to Event Hub`);

  context.res = {
    status: 202,
    body: {
      accepted: true,
      eventId,
      contract: envelope.contract
    }
  };
};